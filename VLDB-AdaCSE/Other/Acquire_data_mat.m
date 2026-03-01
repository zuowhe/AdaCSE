function [data] = Acquire_data_mat(str,D,T,bnet,RootPath)
% Acquire experimental datasets from newly generated or existing data.
% 由数据集产生需要的训练集
n = size(bnet.dag,1);   % #nodes
    data = cell(1,T);
for t=1:T
    data{t} = zeros(n,D);
    for i=1:D
        sample = sample_bnet(bnet);
        data{t}(:,i) = [sample{:}];
    end
end
eval([str, '=data;']);
save(fullfile(RootPath,'[Datasets]', [str '.mat']), str);
end