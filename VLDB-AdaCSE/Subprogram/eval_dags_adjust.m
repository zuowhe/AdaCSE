function [f1,se,sp,pr,shd,TP,TP2,FN,FP,TN] = eval_dags_adjust(dags,dag0,N)
% Get F1 score, Sensitivity/Recall, Specificity, Precision, SHD for a set of DAGs wrt DAG0 (target_dag).
% 与 bayesys,噪声验证论文 中的表述一致
% DAG0 (target_dag):0,1
% DAGs :0,1,2
% SHD :
bns = size(dag0,1);
totP0 = 0;      % #oriented_edges in dag0   Total Positive
totN0 = 0;      % #absent_edges in dag0     Total Negative
for j = 1:bns
    for k = j:bns
        if xor(dag0(j,k),dag0(k,j))
            totP0 = totP0+1;%有边的数目
        else
            totN0 = totN0+1;%无边的数目
        end
    end
end
f1 = zeros(1,N);
se = zeros(1,N);
sp = zeros(1,N);
pr = zeros(1,N);
shd = zeros(1,N);
for i = 1:N
    TP = 0;     % TP: #matching_oriented_edges in dag 1→1
    TP2 = 0;    % Half True Positives (TP*0.5): the number of partially correct edges 01→10,etc.
    FP = 0;     % FP: incorrectly discovering direct dependency 0→1
    TN = 0;     % TN: #matching_absent_edges in dag / correctly discovering direct independency 0→0
    FN = 0;     % FN: edges not discovered 1→0
    totP = 0;       % P: #oriented_edges in dag
    totN = 0;       % N: #absent_edges in dag
    for j = 1:bns
        for k = j:bns
            jk = dags{i}(j,k);  kj = dags{i}(k,j);%自己得出的答案
            jk0 = dag0(j,k); kj0 = dag0(k,j);%标准答案
            if jk + kj == 0
                totN = totN+1;      % 0 0
            else
                totP = totP+1;      % 1 0 / 0 1 / 2 2
            end
            switch jk0
                case 0
                    switch kj0
                        case 0      %     0     0
                            if ~(jk == 0 && kj == 0)
                                FP = FP + 1;
                            else
                                TN = TN + 1;
                            end
                        case 1      %     0     1
                            if     jk == 0 && kj == 0
                                FN = FN + 1;
                            elseif jk == 0 && kj == 1
                                TP = TP + 1;
                            elseif jk == 1 && kj == 0
                                TP2 = TP2 + 1;
                            elseif jk == 2 && kj == 2
                                TP2 = TP2 + 1;
                            end
                    end
                case 1      %     1     0
                    if     jk == 0 && kj == 0
                        FN = FN + 1;
                    elseif jk == 0 && kj == 1
                        TP2 = TP2 + 1;
                    elseif jk == 1 && kj == 0
                        TP = TP + 1;
                    elseif jk == 2 && kj == 2
                        TP2 = TP2 + 1;
                    end
            end
        end
    end
    if totP0==0
        se(i) = 1;    % if true dag is null, sensitivity / recall is 1
    else
        se(i) = (TP + TP2/2)/(TP + TP2/2 + FN);    % TP/totP0
    end
    if totP == 0
        pr(i) = 1;       % if predicted dag is null, precision is 1
    else
        pr(i) = (TP + TP2/2)/(TP + TP2/2 + FP);         % TP/totP
    end
    if totN0 == 0
        sp(i) = 1;    % if true dag is complete, specificity is 1
    else
        sp(i) = TN/totN0;    % TN/totN0
    end
    if pr(i)+se(i) == 0
        f1(i) = 0;
    else
        f1(i) = 2*pr(i)*se(i)/(pr(i)+se(i));
    end
    shd(i) = FP + FN + TP2/2;
end
end