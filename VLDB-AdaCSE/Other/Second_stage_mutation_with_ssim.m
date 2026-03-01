% ********** 关键修改：二次变异（融入SSIM）**********
function [p] = Second_stage_mutation_with_ssim(l_map, p, all_repeats, g_best)
% 功能：根据个体与最优个体的SSIM调整变异率，SSIM越高变异率越低
repeat_size = length(all_repeats);
l_cnt = size(l_map,1);
if l_cnt == 0
    return;
end

for I = 1:repeat_size
    idx = all_repeats(I);
    current_ind = p{idx};
    % 计算当前个体与最优个体的SSIM
    ssim = dag_ssim(current_ind, g_best);
    
    % 变异率与SSIM负相关：SSIM高则变异率低（保留优质结构）
    base_m = 1 / l_cnt;  % 基础变异率
    m = base_m * (1 - ssim);  % 调整后变异率（0~base_m）
    
    % 对每条边进行变异
    for L = 1:l_cnt
        j = l_map(L,1);
        k = l_map(L,2);
        if m >= rand
            l_val = get_allele(current_ind(j,k), current_ind(k,j));
            % 变异操作（同原逻辑）
            switch l_val
                case 1
                    if rand > 0.5
                        current_ind(j,k) = false; current_ind(k,j) = true;
                    else
                        current_ind(j,k) = true; current_ind(k,j) = false;
                    end
                case 2  
                    if l_map(L,3) > rand
                        current_ind(j,k) = true; current_ind(k,j) = false;
                    else
                        current_ind(j,k) = false; current_ind(k,j) = false;
                    end
                case 3  
                    if l_map(L,3) > rand
                        current_ind(j,k) = false; current_ind(k,j) = true;
                    else
                        current_ind(j,k) = false; current_ind(k,j) = false;
                    end
            end
        end
    end
    p{idx} = current_ind;  % 更新子代
end
end