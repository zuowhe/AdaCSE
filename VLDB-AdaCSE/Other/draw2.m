% 定义 deltaBIC 范围
delta_BIC = linspace(-20, 20, 1000); % 从 -20 到 20，取 1000 个点

% 初始化 gamma 值
gamma = zeros(size(delta_BIC));

% 计算分段函数值
for i = 1:length(delta_BIC)
    if delta_BIC(i) >= 0
        % 对于 ΔBIC ≥ 0 的部分
        gamma(i) = exp(-delta_BIC(i));
    else
        % 对于 ΔBIC < 0 的部分
        gamma(i) = 1 - exp(delta_BIC(i))+1.5;
    end
end

% 绘制曲线
figure;
plot(delta_BIC, gamma, 'LineWidth', 1.5);
xlabel('\Delta BIC');
ylabel('\lambda');
title('分段函数曲线 (\Delta BIC 从 -20 到 20)');
grid on;

% 设置坐标轴范围
xlim([-20, 20]);
ylim([-1, 3]);