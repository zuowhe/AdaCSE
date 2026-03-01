function mutated_agent = maga_mutation(agent, BN_NodesNum)
%MAGA_MUTATION Implements the structure-aware mutation from the MAGA paper (Algorithm 4).
%
%   mutated_agent = maga_mutation(agent, BN_NodesNum)
%
%   This operator performs a local, graph-based mutation on a single agent.
%   The process is as follows:
%   1. Two distinct nodes, node1 and node2, are chosen randomly.
%   2. If an edge exists between them (in either direction):
%      a. With 50% probability, the edge is REVERSED.
%      b. With 50% probability, the edge is REMOVED.
%   3. If no edge exists between them:
%      a. With 50% probability, an edge node1 -> node2 is ADDED.
%      b. With 50% probability, an edge node2 -> node1 is ADDED.
%
%   Inputs:
%       agent           - The agent to be mutated (a binary row vector).
%       BN_NodesNum     - The number of nodes in the Bayesian Network.
%
%   Output:
%       mutated_agent   - The new agent after applying the mutation.

    % 1. 随机选择两个不同的节点
    nodes = randperm(BN_NodesNum, 2);
    node1 = nodes(1);
    node2 = nodes(2);

    adj_matrix = reshape(agent, BN_NodesNum, BN_NodesNum)';

    % 2. 检查两个节点之间是否存在边
    edge_1_to_2_exists = (adj_matrix(node1, node2) == 1);
    edge_2_to_1_exists = (adj_matrix(node2, node1) == 1);

    if edge_1_to_2_exists
        if rand < 0.5
            adj_matrix(node1, node2) = 0;
            adj_matrix(node2, node1) = 1;
        else
            adj_matrix(node1, node2) = 0;
        end
    elseif edge_2_to_1_exists
        if rand < 0.5
            adj_matrix(node2, node1) = 0;
            adj_matrix(node1, node2) = 1;
        else
            adj_matrix(node2, node1) = 0;
        end
    else
        if rand < 0.5
            adj_matrix(node1, node2) = 1;
        else
            adj_matrix(node2, node1) = 1;
        end
    end

    mutated_agent = reshape(adj_matrix', 1, BN_NodesNum * BN_NodesNum);
end