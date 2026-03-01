function [score, cache, total_overwrite] = MAGA_score_dags_recover(data, ns, dags, varargin)
% SCORE_DAGS Compute the score of one or more DAGs using per-node caching.
% (Function has been modified to accept both N*N matrix and 1*(N*N) vector formats)

[n, ncases] = size(data);
type = cell(1, n);
params = cell(1, n);
for i = 1:n
    type{i} = 'tabular';
    params{i} = {'prior_type', 'dirichlet', 'dirichlet_weight', 1};
end
scoring_fn = 'bayesian';
discrete = 1:n;
clamped = zeros(n, ncases);
cache = [];
max_cache_size = 100;

args = varargin;
nargs = length(args);
for i = 1:2:nargs
    switch args{i}
        case 'scoring_fn', scoring_fn = args{i+1};
        case 'type',       type = args{i+1};
        case 'discrete',   discrete = args{i+1};
        case 'clamped',    clamped = args{i+1};
        case 'params',     params = args{i+1};
        case 'cache',      cache = args{i+1};
        case 'max_cache_size', max_cache_size = args{i+1};
    end
end

NG = length(dags);
score = zeros(1, NG);
total_overwrite = 0;

% ==================== 新增: 格式检测与转换模块 ====================
if NG > 0 && ~isempty(dags{1})
    first_dag = dags{1};
    
    % 检查第一个体是向量还是矩阵
    if isvector(first_dag)
        % --- 新格式: 1 x (N*N) 向量 ---
        %fprintf('Detected vector format. Converting to matrix for scoring.\n');
        
        % 验证向量长度是否正确
        expected_len = n * n;
        if numel(first_dag) ~= expected_len
            error('Input vector size (%d) does not match expected size (%d x %d = %d).', ...
                  numel(first_dag), n, n, expected_len);
        end
        
        % 创建一个新的 cell 数组来存储转换后的矩阵
        dags_matrix_format = cell(1, NG);
        for i = 1:NG
            if ~isempty(dags{i})
                % 将 1x(N*N) 向量变回 N*N 矩阵
                % reshape(vector', N, N)' 假设向量是按行展开的
                dags_matrix_format{i} = reshape(dags{i}', n, n)';
            else
                dags_matrix_format{i} = [];
            end
        end
        % 用转换后的矩阵格式覆盖原始输入
        dags = dags_matrix_format;
        
    elseif ~ismatrix(first_dag) || size(first_dag, 1) ~= size(first_dag, 2)
        % 如果不是向量也不是方阵，则格式错误
        error('Unsupported DAG format. Input must be a cell array of square matrices or 1x(N*N) vectors.');
    end
    % 如果已经是 N x N 矩阵 (旧格式)，则无需任何操作，直接进入后续循环
end
% =================================================================

for g = 1:NG
    if isempty(dags{g})
        score(g) = -Inf;
        continue;
    end
    
    dag_to_score = dags{g};
    
    % (可选，但推荐) 确保矩阵是 logical 类型
    if ~islogical(dag_to_score)
        dag_to_score = logical(dag_to_score);
    end

    for j = 1:n
        % 核心评分逻辑完全不变
        ps = parents(dag_to_score, j);
        [scor, cache, hit_count, overwrite_count] = score_family_recover(j, ps, type{j}, ns, discrete, data, params{j}, cache, max_cache_size);
        score(g) = score(g) + scor;
        total_overwrite = total_overwrite + overwrite_count;
    end
end

end

% --- score_family_recover 及其辅助函数无需任何改动 ---
% function [score, cache, cache_hit_count, overwrite_count] = score_family_recover(...)
% ...
% end
% function [found, score] = check_cache(...)
% ...
% end
% function cj_new = add_to_cache(...)
% ...
% end