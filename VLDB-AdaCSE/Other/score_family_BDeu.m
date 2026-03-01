function [score, cache, cache_hit_count, overwrite_count] = score_family_BDeu(j, ps, node_type, ns, discrete, data, args, cache, max_cache_size)
% SCORE_FAMILY_RECOVER 计算节点 j 的 BDeu 分数，并使用带容量限制的缓存机制
% 输出：
%   score           - 当前父集对应的评分
%   cache           - 更新后的缓存结构
%   cache_hit_count - 本次调用中缓存命中的次数（0 或 1）
%   overwrite_count - 在本次调用中发生的覆盖次数

if nargin < 10 || isempty(max_cache_size)
    max_cache_size = 100;
end

if nargin < 9 || isempty(cache)
    n_nodes = size(data, 1);
    cache = cell(1, n_nodes);
    for k = 1:n_nodes
        cache{k} = struct('masks', [], 'scores', []);
    end
end

% 初始化命中和覆盖计数器
cache_hit_count = 0;
overwrite_count = 0;

misv = -9999;
ccc = iscell(data);
if ccc
    data = bnt_to_mat(data, misv);
end

ps = unique(ps);
[n, ncases] = size(data);

% 查找缓存
[found, score] = check_cache(cache{j}, ps);
if found
    cache_hit_count = 1; % 命中一次
    return;
end

% 构造子图
dag = zeros(n);
if ~isempty(ps)
    dag(ps, j) = 1;
    ps = sort(ps);
end

% 创建网络和 CPD
bnet = mk_bnet(dag, ns, 'discrete', discrete);
fname = sprintf('%s_CPD', node_type);
if isempty(args)
    bnet.CPD{j} = feval(fname, bnet, j);
else
    bnet.CPD{j} = feval(fname, bnet, j, args{:});
end

% 学习参数 & 评分
fam = [ps j];
[tmp, available_case] = find(data(fam,:) == misv);
available_case = setdiff(1:ncases, available_case);

bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:, available_case), ns, bnet.cnodes);

% BDeu 参数设置
alpha = 1;  % 等效样本大小，常设为 1

% 获取当前节点的状态数
r_i = ns(j);  % 节点 j 的状态数

% 父节点组合数
q_i = 1;
for k = 1:length(ps)
    q_i = q_i * ns(ps(k));
end

% 如果没有父节点，则只有一种父状态
if isempty(ps)
    q_i = 1;
end

% 构建联合频率表
parents_data = data(ps, available_case)';
child_data = data(j, available_case)';
joint_data = [parents_data, child_data];

% 统计每个父状态和子状态的组合频数
unique_parents = unique(parents_data, 'rows');
num_parent_states = size(unique_parents, 1);

N_ik = zeros(num_parent_states, 1);     % 每个父状态的总样本数
N_ijk = zeros(num_parent_states, r_i);  % 每个父状态下的子状态频数

for k = 1:num_parent_states
    idx = ismember(parents_data, unique_parents(k,:), 'rows');
    parent_samples = child_data(idx);
    
    N_ik(k) = length(parent_samples);
    
    for s = 1:r_i
        N_ijk(k,s) = sum(parent_samples == s);
    end
end

% BDeu 得分计算
score = 0;

for k = 1:num_parent_states
    total = N_ijk(k,:);
    score = score + gammaln(alpha / q_i) - gammaln(alpha / q_i + N_ik(k));
    for s = 1:r_i
        score = score + gammaln(alpha/(q_i*r_i) + total(s)) - gammaln(alpha/(q_i*r_i));
    end
end

% 添加到缓存
cache{j} = add_to_cache_BDeu(cache{j}, ps, score, max_cache_size, n);

% 获取覆盖计数
overwrite_count = cache{j}.overwrite_count;

end



function cj_new = add_to_cache_BDeu(cj, ps, score, max_cache_size, total_nodes)
% ADD_TO_CACHE 将新的父集及其得分加入缓存，并限制最大条目数（FIFO策略）
%
% 输入参数：
%   cj             - 当前缓存结构体（每个节点一个）
%   ps             - 父节点索引列表（可能为空）
%   score          - 要存储的评分值
%   max_cache_size - 最大缓存条目数
%   total_nodes    - 总节点数量（用于构造 mask 的维度）
%
% 输出参数：
%   cj_new         - 更新后的缓存结构体
%

% 检查是否传入了 total_nodes，否则尝试从已有缓存中推断
if nargin < 5 || isempty(total_nodes)
    if ~isempty(cj.masks) && size(cj.masks, 2) > 0
        total_nodes = size(cj.masks, 2);
    else
        error('必须提供 total_nodes 参数或已有缓存数据');
    end
end

% 构造 mask：total_nodes 维度的逻辑向量
mask = false(1, total_nodes);
if ~isempty(ps)
    unique_ps = unique(ps);
    mask(unique_ps) = true;
end

% 如果缓存中没有 overwrite_count 字段，则初始化为 0
if ~isfield(cj, 'overwrite_count')
    cj.overwrite_count = 0;
end

% 如果缓存为空，直接初始化
if isempty(cj.masks)
    cj.masks = mask;
    cj.scores = score;
else
    % 判断是否超出最大缓存容量
    if size(cj.masks, 1) >= max_cache_size
        % 移除最早的一条记录（FIFO）
        cj.masks = cj.masks(2:end, :);
        cj.scores = cj.scores(2:end);
        % 增加覆盖计数器
        cj.overwrite_count = cj.overwrite_count + 1;
    end

    % 添加新记录到缓存末尾
    cj.masks(end+1, :) = mask;
    cj.scores(end+1) = score;
end

% 返回更新后的缓存结构体
cj_new = cj;

end


function [found, score] = check_cache(cj, ps)
N = size(cj.masks, 2);
mask = false(1, N);
mask(ps) = true;

found = false;
score = 0;

for i = 1:size(cj.masks, 1)
    if isequal(cj.masks(i,:), mask)
        found = true;
        score = cj.scores(i);
        return;
    end
end
end