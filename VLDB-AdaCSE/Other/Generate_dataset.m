%% 根据输入的网络名称和数据规模，生成实验所需的训练集
function Bnets = Generate_dataset(DsS, trial, Flag)      % function [output1, output2] = myFunction(input1, input2)
    RootPath = fileparts(mfilename('fullpath'));   % 获取当前文件的根目录
    Bnets = cell(0,0);
    for j = 1:size(DsS,2)     % 第一层循环，遍历多个网络，即{网络名称，包含数据规模的数组}
        switch DsS{j}{1,1}
            % ================= Small ======================= 节点数 == 边/弧 == 参数 == 最大入度
            case 'Asia',        bnet = mk_asia_bnet;      %     8        8       18        2
            case 'Cancer',      bnet = mk_cancer_bnet;    %     5        4       10        2
            case 'Earthquake',  bnet = mk_earthquake_bnet;%     5        4       10        2
            case 'Sachs',       bnet = mk_sachs_bnet;     %    11       17      178        3
            case 'Survey',      bnet = mk_survey_bnet;    %     6        6       21        2
            % ================ Medium ======================= 节点数 == 边/弧 == 参数 == 最大入度
            case 'Alarm',       bnet = mk_alarm_bnet;     %    37       46      509        4
            case 'Barley',      bnet = mk_barley_bnet;    %    48       84   114005        4
            case 'INS',         bnet = mk_insur_bnet;     %    27       52      984        3
            case 'Mildew',      bnet = mk_mildew_bnet;    %    35       46   540150        3
            case 'Water',       bnet = mk_water_bnet;     %    32       66    10083        5
            % ================= Large ======================= 节点数 == 边/弧 == 参数 == 最大入度
            case 'Hailfinder',  bnet = mk_hailfinder_bnet;%    56       66     2656        4
            case 'HEPAR',       bnet = mk_hepar2_bnet;    %    70      123     1453        6
            case 'Win95pts',    bnet = mk_win95pts_bnet;  %    76      112      574        7
            % =============== Very Large ==================== 节点数 == 边/弧 == 参数 == 最大入度
            case 'AND',         bnet = mk_andes_bnet;     %   223      338     1157        6
            case 'Pathfinder',  bnet = mk_pathfinder_bnet;%   109      195    77155        5
        end
        Bnets{end+1} = {DsS{j}{1,1},bnet};            % Bnets统计实验所涉及的网络,内容为{网络名称1，网络结构体1；网络名称2，网络结构体2；}
        if Flag
            for i = 1:size(DsS{j}{1,2},2)    % 第二层循环，遍历数组的内容，根据设置的规模依次生成训练集
                    Ds_size = DsS{j}{1,2}(i);    % 获取数据集大小
                    str = sprintf('%s%s',DsS{j}{1,1},num2str(Ds_size));
                    fprintf('Generating %s datasets.     Start time [%s]\n',str,datestr(now));
                    [~] = Acquire_data_mat(str,Ds_size,trial,bnet,RootPath);    % 由BN网络产生训练集，并保存在[Datasets]文件夹下
                    % [~] = Acquire_data_csv(str,Ds_size,trial,gen_new_data,bnet);
                    fprintf('- Dataset %s is generated. Finish time [%s]\n',str,datestr(now));
            end
        else 
            fprintf('No need to generate new datasets.\n')
        end
    end
end