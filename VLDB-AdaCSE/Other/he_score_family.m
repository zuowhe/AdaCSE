function [score, cache, flag_cache] = he_score_family(j, ps, node_type, scoring_fn, ns, discrete, data, args, cache)
flag_cache = 0;
if (nargin<9 || isempty(cache)) , c=0; else c=1; end
%tic
if c==1
    [b,score]=score_find_in_cache(cache,j,ps,scoring_fn);
else
    b=0;
end

ccc = iscell(data);
ps = unique(ps);

if b==0
    misv = -9999;
    if ccc, data = bnt_to_mat(data,misv); end
    [n, ncases] = size(data);
    dag = zeros(n,n);
    
    if ~isempty(ps), dag(ps, j) = 1; ps = sort(ps); end

    bnet = mk_bnet(dag, ns, 'discrete', discrete);
    fname = sprintf('%s_CPD', node_type);
    if isempty(args)
        bnet.CPD{j} = feval(fname, bnet, j);
    else
        bnet.CPD{j} = feval(fname, bnet, j, args{:});
    end
    %tic
    switch scoring_fn
    case 'bic'
        fam = [ps j];
        if ccc
            [~, available_case] = find(data(fam,:)==misv);
            available_case = mysetdiff(1:ncases, available_case);
        else
            available_case = 1:ncases;
        end
        bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:,available_case), ns, bnet.cnodes);

        L = log_prob_node(bnet.CPD{j}, data(j,available_case), data(ps,available_case));
        S = struct(bnet.CPD{j}); 
        score = L - 0.5*S.nparams*log(length(available_case));
    case 'bicmod'
        fam = [ps j];
        if ccc
            [~, available_case] = find(data(fam,:)==misv);
            available_case = mysetdiff(1:ncases, available_case);
        else
            available_case = 1:ncases;
        end
        bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:,available_case), ns, bnet.cnodes);
        L = log_prob_node(bnet.CPD{j}, data(j,available_case), data(ps,available_case));
        S = struct(bnet.CPD{j}); 
        score = L - S.nparams*log(length(available_case));
    case 'bayesian'
        fam = [ps j];
        if ccc
            [~, available_case] = find(data(fam,:)==misv);
            available_case = mysetdiff(1:ncases, available_case);
        else
            available_case = 1:ncases;
        end
        score = log_marg_prob_node(bnet.CPD{j}, data(j,available_case), data(ps,available_case));
        otherwise
        error(['unrecognized scoring fn ' scoring_fn]);
    end

    if c==1
        [cache,flag_cache]=score_add_to_cache(cache,j,ps,score,scoring_fn);
    end
end

%===========================Inner functions

function [cache,flag_cache] = score_add_to_cache(cache,j,ps,score,scoring_fn)
flag_cache = 0;
N=size(cache,2)-3;
L=size(cache,1)-2;
cache_full=cache(1,2) ;

if ismember(j,ps)
    disp('This is a cyclic entry, nothing was done.');
elseif j>N || j<=0
    disp('This entry is not valid, nothing was done.');
else
    switch scoring_fn
    case 'bic'
        fn=1;
    case 'bayesian'
        fn=2;
    otherwise
        fn=3;
    end

    if ~cache_full
        place=cache(1,1) + 1;
    else
        place = mod(cache(1,1),L)+3; 
        % 父集结构的预设内存不足，从替换掉
        flag_cache = 1;
    end

    cache(place,:)=0;       % 第place行置为0
    cache(place,ps)=1;
    cache(place,N+1)=j;
    cache(place,N+2)=score;
    cache(place,N+3)=fn;

    cache(1,1)=place;
    if place>L || cache(1,2)~=0
        cache(1,2)=1;
    end
end


%=========================================================================================
function [bool, score] = score_find_in_cache(cache,j,ps,~)

    L=size(cache,1)-2;
    N=size(cache,2)-3;
    cache_full=cache(1,2);

    if N<1
        bool=0;
        score=0;
        return
    end

    parents=zeros(1,N);
    parents(ps)=1;
    
    if ~cache_full
        place=cache(1,1);
    else
        place = L+1; 
    end

    % 直接在指定范围内查找第N+1列等于j的行索引
    candidats = find(cache(3:place, N+1) == j);

    % 如果需要将这些索引转换为相对于整个cache矩阵的绝对索引（即加上起始偏移量1）
    candidats = candidats + 2;

    i=1;
    while i<=N && ~isempty(candidats)
        tmp=cache(candidats,i)==parents(i);
        candidats=candidats(tmp);
        i=i+1;
    end

    %Tpre=toc

    bool=~isempty(candidats);

    if bool
        score=cache(candidats(1),N+2);
    else
        score=0;
    end
