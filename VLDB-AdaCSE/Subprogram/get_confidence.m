function [conf, conf_norm] = get_confidence(pop)
% 获得置信度矩阵

N = max(size(pop,2),size(pop,1));
% filename = 'test0.mat';
% save(filename);
bns = size(pop{1},1);
conf = zeros(bns);          % 置信度矩阵
for i = 1:bns
    for j = i:bns
        for ii = 1:N
            % 统计每条边出现的次数
            conf(i,j) = conf(i,j) + pop{ii}(i,j);
            conf(j,i) = conf(j,i) + pop{ii}(j,i);
        end
    end
end

[~,~,conf_list] = find(conf);           % 所有边的支持度
eps = 0.0000001;        % small positive number
conf_min = min(conf_list);
conf_max = max(conf_list);
conf_range = conf_max - conf_min;
conf_norm = (conf-conf_min)/(eps+conf_range); % normalized score
conf_norm(conf_norm < 0) = 0;

end