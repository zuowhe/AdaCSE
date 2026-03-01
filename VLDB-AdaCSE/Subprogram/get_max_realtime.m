function [max_time] = get_max_realtime(BN_NodesNum)
% Get maximum clock time allotted for execution, based on network size.
% 真实运行时间，单位：秒
% 不少于 2x 较快算法平均运行时间

if BN_NodesNum<10             % 小数据集 5个
    max_time = 150;     % 2 min 30 s
elseif BN_NodesNum<30         % Insurance
    max_time = 5000;    % 25 min
elseif BN_NodesNum<40         % Alarm
    max_time = 5000;    % 1 h 23 min
elseif BN_NodesNum<50         % Barley
    max_time = 8000;    % 2 h 13 min
elseif BN_NodesNum<60         % Hailfinder 待定
    max_time = 30000;   % 8 h 20 min
elseif BN_NodesNum<80         % Hepar Win95pts
    max_time = 30000;   % 8 h 20 min
elseif BN_NodesNum<120        % 超大：Pathfinder
    max_time = 40000;   % 11 h 7 min
else                  % 超大：Andes
    max_time = 40000;   % 11 h 7 min
end

end