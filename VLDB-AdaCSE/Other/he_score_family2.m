function [score, cache, flag_cache] = he_score_family2(j, ps, node_type, scoring_fn, ns, discrete, data, args, cache)
    flag_cache = 0;

    % 如果 cache 未初始化，则创建一个新的散列表
    if nargin < 9 || isempty(cache)
        cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end

    % 将当前父集 (ps) 和节点 j 转换为唯一键值
    key = generate_unique_key(j, ps);

    % 检查缓存中是否已存在该键
    if isKey(cache, key)
        % 如果存在，则直接获取评分
        score = cache(key);
        return;
    end

    % 如果不存在，则计算评分
    misv = -9999;
    ps = unique(ps);
    ccc = iscell(data);

    if ccc
        data = bnt_to_mat(data, misv);
    end

    [n, ncases] = size(data);
    dag = zeros(n, n);

    if ~isempty(ps)
        dag(ps, j) = 1;
        ps = sort(ps);
    end

    bnet = mk_bnet(dag, ns, 'discrete', discrete);
    fname = sprintf('%s_CPD', node_type);

    if isempty(args)
        bnet.CPD{j} = feval(fname, bnet, j);
    else
        bnet.CPD{j} = feval(fname, bnet, j, args{:});
    end

    switch scoring_fn
        case 'bic'
            fam = [ps j];
            if ccc
                [~, available_case] = find(data(fam, :) == misv);
                available_case = mysetdiff(1:ncases, available_case);
            else
                available_case = 1:ncases;
            end

            bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:, available_case), ns, bnet.cnodes);
            L = log_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));
            S = struct(bnet.CPD{j});
            score = L - 0.5 * S.nparams * log(length(available_case));

        case 'bicmod'
            fam = [ps j];
            if ccc
                [~, available_case] = find(data(fam, :) == misv);
                available_case = mysetdiff(1:ncases, available_case);
            else
                available_case = 1:ncases;
            end

            bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:, available_case), ns, bnet.cnodes);
            L = log_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));
            S = struct(bnet.CPD{j});
            score = L - S.nparams * log(length(available_case));

        case 'bayesian'
            fam = [ps j];
            if ccc
                [~, available_case] = find(data(fam, :) == misv);
                available_case = mysetdiff(1:ncases, available_case);
            else
                available_case = 1:ncases;
            end

            score = log_marg_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));

        otherwise
            error(['unrecognized scoring fn ' scoring_fn]);
    end

    % 将评分保存到散列表中
    cache(key) = score;
end
function key = generate_unique_key(j, ps)
    % 将边的位置按字典序排序
    sorted_ps = sort(ps);

    % 将节点 j 和父集 ps 组合成字符串形式的键值
    key_str = sprintf('%d_', j);  % 添加节点编号作为前缀
    for i = 1:length(sorted_ps)
        key_str = [key_str, sprintf('%d_', sorted_ps(i))];
    end

    % 返回键值
    key = key_str;
end