% ********** 新增函数1：计算两个DAG的结构相似度（SSIM）**********
function ssim = dag_ssim(dag1, dag2)
% 基于节点父集重叠度计算结构相似度
% 公式：SSIM = (2*sum(交集) + C) / (sum(父集1) + sum(父集2) + C)，C为平滑常数
bns = size(dag1,1);
C = 1e-4;  % 避免分母为0
total_ssim = 0;

for node = 1:bns
    % 获取节点的父集（父节点索引）
    parent1 = find(dag1(:,node));  % dag1中node的父集
    parent2 = find(dag2(:,node));  % dag2中node的父集
    
    % 计算父集交集大小
    intersect_size = length(intersect(parent1, parent2));
    sum1 = length(parent1);
    sum2 = length(parent2);
    
    % 节点级SSIM
    node_ssim = (2*intersect_size + C) / (sum1 + sum2 + C);
    total_ssim = total_ssim + node_ssim;
end

ssim = total_ssim / bns;  % 平均得到整体SSIM
end