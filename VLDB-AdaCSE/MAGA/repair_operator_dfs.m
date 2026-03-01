function repaired_agent = repair_operator_dfs(agent, BN_NodesNum)
%REPAIR_OPERATOR_DFS Implements the cycle repair mechanism using Depth First Search (DFS).
%
%   repaired_agent = repair_operator_dfs(agent, BN_NodesNum)
%
%   This version does NOT require the Graph and Network Algorithms Toolbox.
%   It finds and breaks cycles one by one until the graph is a DAG.

    adj_matrix = reshape(agent, BN_NodesNum, BN_NodesNum)';

    while true
        % --- 调用DFS辅助函数来检测并修复一个环路 ---
        % has_cycle 会在找到第一个环路时立即返回 true 和修复后的矩阵
        [adj_matrix, has_cycle] = find_and_break_one_cycle(adj_matrix, BN_NodesNum);
        
        % 如果 find_and_break_one_cycle 完成一次全图扫描且没发现环路，
        % 那么 has_cycle 会是 false，我们可以退出主循环。
        if ~has_cycle
            break;
        end
    end
    repaired_agent = naive_limit_parents(8,adj_matrix);
    repaired_agent = reshape(repaired_agent', 1, BN_NodesNum * BN_NodesNum);
 
end


function [adj, has_cycle] = find_and_break_one_cycle(adj, n)
% 辅助函数：遍历所有节点，启动DFS来寻找并破坏第一个遇到的环路

    % 节点状态: 0 = white (未访问), 1 = gray (访问中), 2 = black (已完成)
    color = zeros(1, n); 
    
    has_cycle = false;

    for i = 1:n
        if color(i) == 0 % 如果节点尚未被访问
            [adj, has_cycle, color] = dfs_visit(i, adj, color);
            if has_cycle
                return; 
            end
        end
    end
end


function [adj, has_cycle, color] = dfs_visit(u, adj, color)
% 核心DFS递归函数

    color(u) = 1; % 标记为 gray (正在访问)
    has_cycle = false;
    
    neighbors = find(adj(u, :)); % 找到节点u的所有出邻居
    
    for v = neighbors
        if color(v) == 1 % 发现回边，找到了一个环！
%             has_cycle = true;
%             
%             % --- 执行修复操作 ---
%             % 我们找到了构成环路的边 (u, v)
%             if rand < 0.5
%                 % 50% 概率删除
%                 adj(u, v) = 0;
%             else
%                 % 50% 概率反转
%                 adj(u, v) = 0;
%                 adj(v, u) = 1;
%             end
%             % 找到并修复后，立即返回，不再继续搜索
%             return; 



                has_cycle = true;
                
                % --- 暂时只使用删除 ---
                adj(u, v) = 0; 
    
    return;
        end
        
        if color(v) == 0 % 如果邻居是 white，则递归访问
            [adj, has_cycle, color] = dfs_visit(v, adj, color);
            if has_cycle
                return; % 如果子递归发现了环，立即层层返回
            end
        end
    end
    
    color(u) = 2; % 节点u的所有邻居都已访问完毕，标记为 black
end