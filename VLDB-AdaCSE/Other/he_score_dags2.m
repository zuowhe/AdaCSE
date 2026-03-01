function [score, cache,flag_cache] = he_score_dags2(data, ns, dags, varargin)

[n,ncases] = size(data);

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

NG = 1;
score = zeros(1, NG);

for j=1:n
    if isclamped %DWH
        u = find(clamped(j,:)==0);
    end
    for g=1:NG
        if isempty(dags)
            score(g)=-Inf;
        else
            ps = parents(dags, j);
            [scor,cache,flag_cache] = he_score_family2(j, ps, type{j}, scoring_fn, ns, discrete, data(:,u), params{j}, cache);
            score(g) = score(g) + scor;
        end
    end
end