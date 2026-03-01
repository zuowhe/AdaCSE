function [score, cache] = score_dags_norecover(data, ns, dags, varargin)
% SCORE_DAGS_NORECOVER 批量计算 DAG 的 BIC 分数，使用规范化缓存机制
%
% 输入：
%   data      - 数据矩阵 (n x N)
%   ns        - 节点状态数 (n x 1)
%   dags      - DAG 集合 {1 x NG}
%   varargin  - 可选参数：'type', 'discrete', 'params', 'cache'
%
% 输出：
%   score     - 每个 DAG 的总 BIC 分数 (1 x NG)
%   cache     - 更新后的缓存（Map）

%% 默认参数
n = size(data, 1);
type = cell(1, n);
params = cell(1, n);
for i = 1:n
    type{i} = 'tabular';
    params{i} = {};
end
discrete = 1:n;

%% 解析可选参数
args = varargin;
nargs = length(args);
cache = []; % 初始化为空

for i = 1:2:nargs
    if i+1 > nargs
        error('Missing value for parameter: %s', args{i});
    end
    switch lower(args{i})
        case 'type'
            type = args{i+1};
        case 'discrete'
            discrete = args{i+1};
        case 'params'
            params = args{i+1};
            if isempty(params)
                params = cell(1,n);
            end
        case 'cache'
            cache = args{i+1};
        otherwise
            warning('Unknown parameter: %s, ignored.', args{i});
    end
end

%% 确保 cache 是 containers.Map，键类型为 char（字符串）
if isempty(cache)
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
elseif ~isa(cache, 'containers.Map')
    error('Parameter ''cache'' must be a containers.Map object.');
end

%% 初始化输出
NG = length(dags);
score = zeros(1, NG);

%% 遍历每个 DAG
for g = 1:NG
    if isempty(dags{g})
        score(g) = -inf;
        continue;
    end
    
    dag = dags{g};
    local_score = 0;
    
    for j = 1:n
        ps = parents(dag, j); % 获取父节点
        [scor, cache] = score_family_norecover(j, ps, type{j}, ns, discrete, data, params{j}, cache);
        if isfinite(scor)
            local_score = local_score + scor;
        else
            local_score = -inf;
            break; % 一旦有一个节点为 -inf，整个 DAG 分数为 -inf
        end
    end
    
    score(g) = local_score;
end

end


% ========== 内联函数：parents ==========
function pa = parents(dag, j)
% 获取节点 j 的父节点索引
    pa = find(dag(:,j))';
end