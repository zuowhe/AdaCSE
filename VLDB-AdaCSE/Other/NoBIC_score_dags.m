function [score, cache] = NoBIC_score_dags(data, ns, dags, varargin)

[n, ncases] = size(data);

% set default params
type = cell(1,n);
params = cell(1,n);
cache=[];
for i=1:n
  type{i} = 'tabular';
  params{i} = { 'prior_type', 'dirichlet', 'dirichlet_weight', 1 };
end
scoring_fn = 'bayesian';
discrete = 1:n;

isclamped = 0; % DWH
clamped = zeros(n, ncases);
u = [1:ncases]'; % DWH

args = varargin;
nargs = length(args);
for i=1:2:nargs
  switch args{i},
   case 'scoring_fn', scoring_fn = args{i+1};
   case 'type',       type = args{i+1};
   case 'discrete',   discrete = args{i+1};
   case 'clamped',    clamped = args{i+1}, isclamped = 1; %DWH
   case 'params',     if isempty(args{i+1}), params = cell(1,n); else params = args{i+1};  end
   case 'cache',      cache=args{i+1} ;
  end
end

NG = length(dags);
score = zeros(1, NG);

for j=1:n
    if isclamped %DWH
        u = find(clamped(j,:)==0);
    end
    for g=1:NG
        if isempty(dags{g})
            score(g)=-Inf;
        else
            ps = parents(dags{g}, j);
            [scor] = No_BIC_score_family(j, ps, type{j}, scoring_fn, ns, discrete, data(:,u), params{j});
            score(g) = score(g) + scor;
        end
    end
end

function [score] = No_BIC_score_family(j, ps, node_type, scoring_fn, ns, discrete, data, args)
% SCORE_FAMILY_COMPLETE 计算一个节点及其父节点的评分，给定完全观测的数据
% score = score_family(j, ps, node_type, scoring_fn, ns, discrete, data, args)
%
% data(i,m) 是第i个节点在第m个案例中的值（如果包含缺失值，使用可用的完整案例）
% args 是一个包含传递给构造函数的可选参数的单元格数组，或者如果没有则为空
%
% 创建一个贝叶斯网络，只连接父节点和目标节点，
% 其中目标节点有指定类型的CPD（使用默认参数）。
% 然后评估它的评分（'bic' 或 'bayesian'）

ccc = iscell(data);
ps = unique(ps);

misv = -9999;
if ccc, data = bnt_to_mat(data,misv); end
[n, ncases] = size(data);
dag = zeros(n, n);
if ~isempty(ps), dag(ps, j) = 1; ps = sort(ps); end

bnet = mk_bnet(dag, ns, 'discrete', discrete);
fname = sprintf('%s_CPD', node_type);
if isempty(args)
    bnet.CPD{j} = feval(fname, bnet, j);
else
    bnet.CPD{j} = feval(fname, bnet, j, args{:});
end

switch scoring_fn
    case 'bic',
        fam = [ps j];
        if ccc,
            [tmp, available_case] = find(data(fam, :) == misv);
            available_case = mysetdiff(1:ncases, available_case);
        else
            available_case = 1:ncases;
        end
        bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:, available_case), ns, bnet.cnodes);
        L = log_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));
        S = struct(bnet.CPD{j}); % 打破对象隐私
        score = L - 0.5 * S.nparams * log(length(available_case));
    case 'bicmod',
        fam = [ps j];
        if ccc,
            [tmp, available_case] = find(data(fam, :) == misv);
            available_case = mysetdiff(1:ncases, available_case);
        else
            available_case = 1:ncases;
        end
        bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:, available_case), ns, bnet.cnodes);
        L = log_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));
        S = struct(bnet.CPD{j}); % 打破对象隐私
        score = L - S.nparams * log(length(available_case));
    case 'bayesian',
        fam = [ps j];
        if ccc,
            [tmp, available_case] = find(data(fam, :) == misv);
            available_case = mysetdiff(1:ncases, available_case);
        else
            available_case = 1:ncases;
        end
        score = log_marg_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));
    otherwise,
        error(['无法识别的评分函数 ' scoring_fn]);
end

