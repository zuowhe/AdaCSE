function [CI_new,count_CIchange] = updateCI2(p_avg, N, M, nodesNum, Dif_BIC, CI_new,count_CIchange)
    % CI_avg: 节点的平均CI值
    % N: 种群大小
    % M: 总迭代次数
    %-Dif_BIC: BIC增量
%     beta = 1;
%     numerator = p_avg * ((N / M)* beta);
    CI_initial = p_avg / nodesNum;
%     CI_initial = 1 / M;
    if CI_new==0
        CI_new = CI_initial;
    else
 %% 仅在增量小于0的情况下增加搜索空间
        if Dif_BIC<0
%             sigmoid_value = 1 - exp(Dif_BIC);
            sigmoid_value = 1 / (1 + exp(Dif_BIC));
                if isinf(sigmoid_value) || isnan(sigmoid_value)
                    % disp('Warning: exp(-BIC) resulted in NaN or Inf');
                    sigmoid_value = 0;  % 使用一个合理的默认值来避免数值不稳定
                end
            CI_new = CI_initial*sigmoid_value + CI_new;
            count_CIchange = count_CIchange + 1;
        end
    end
end
