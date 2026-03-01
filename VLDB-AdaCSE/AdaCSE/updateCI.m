function [CI_new,count_CIchange] = updateCI(p_avg, N, M, nodesNum, Dif_BIC, CI_new,count_CIchange)
    CI_initial = p_avg / nodesNum;
    if CI_new==0
        CI_new = CI_initial;
    else
        if Dif_BIC<0
            CI_ins = (1-CI_initial) /M;
            sigmoid_value = 1 - exp(Dif_BIC);
            CI_new = CI_ins*sigmoid_value + CI_new;
            count_CIchange = count_CIchange + 1;
        end

    end
end
