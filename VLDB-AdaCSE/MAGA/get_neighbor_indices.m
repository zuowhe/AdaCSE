function neighbor_indices = get_neighbor_indices(k, L_size)
%GET_NEIGHBOR_INDICES Finds the 1D indices of neighbors on a 2D logical grid.
%
%   neighbor_indices = get_neighbor_indices(k, L_size)
%
%   This function simulates a 2D grid of size L_size x L_size laid out in a
%   1D array (row-major order). Given the 1D index 'k' of an agent, it
%   returns the 1D indices of its four cardinal neighbors (up, down, left, right).
%
%   The grid has toroidal (wrap-around) boundaries.
%
%   Inputs:
%       k               - The 1D index of the current agent (1 to L_size*L_size).
%       L_size          - The side length of the square logical grid.
%
%   Output:
%       neighbor_indices - A 1x4 vector containing the 1D indices of the
%                          [up, down, left, right] neighbors.
%
%   Example:
%       For a 10x10 grid (L_size = 10):
%       - get_neighbor_indices(1, 10) would return the neighbors of the top-left
%         agent (index 1), which are [91, 11, 10, 2].
%         (Up=91, Down=11, Left=10, Right=2)

    % 1. 将一维索引 k 转换为二维坐标 (row, col)
    % 1-based indexing for row and col.
    row = floor((k - 1) / L_size) + 1;
    col = mod(k - 1, L_size) + 1;

    % 2. 计算四个邻居的二维坐标，并应用环形边界逻辑
    
    % 上邻居
    up_row = row - 1;
    if up_row < 1
        up_row = L_size; % 从顶部环绕到底部
    end

    % 下邻居
    down_row = row + 1;
    if down_row > L_size
        down_row = 1; % 从底部环绕到顶部
    end

    % 左邻居
    left_col = col - 1;
    if left_col < 1
        left_col = L_size; % 从左侧环绕到右侧
    end

    % 右邻居
    right_col = col + 1;
    if right_col > L_size
        right_col = 1; % 从右侧环绕到左侧
    end
    
    % 3. 将邻居的二维坐标转回一维索引
    % 公式: index = (row - 1) * L_size + col
    
    idx_up    = (up_row - 1) * L_size + col;
    idx_down  = (down_row - 1) * L_size + col;
    idx_left  = (row - 1) * L_size + left_col;
    idx_right = (row - 1) * L_size + right_col;

    % 4. 返回包含所有邻居索引的数组
    neighbor_indices = [idx_up, idx_down, idx_left, idx_right];
end