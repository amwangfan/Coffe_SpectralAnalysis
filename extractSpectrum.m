% filepath: e:\MATLABcode\Coffe\2.m

function extractSpectrum()
    % 1. 载入图像并允许用户选择感兴趣的区域
    [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp', '图像文件 (*.jpg, *.png, *.bmp)'}, '选择包含光谱的图像');
    if filename == 0
        disp('未选择图像，程序终止');
        return;
    end
    
    img = imread(fullfile(pathname, filename));
    figure('Name', '原始图像', 'NumberTitle', 'off');
    imshow(img);
    title('在图像上框选光谱区域');
    
    % 让用户选择一个矩形区域
    roi = drawrectangle();
    wait(roi);
    
    % 获取矩形区域的坐标
    pos = round(roi.Position);
    x = pos(1);
    y = pos(2);
    width = pos(3);
    height = pos(4);
    
    % 提取选定区域
    spectralRegion = img(y:y+height-1, x:x+width-1, :);
    
    % 显示选定的区域
    figure('Name', '提取的光谱区域', 'NumberTitle', 'off');
    imshow(spectralRegion);
    title('提取的光谱区域');
    
    % 2. 分析光谱
    % 计算每一列的平均RGB值 (将垂直方向压缩)
    avgSpectrum = squeeze(mean(spectralRegion, 1));
    
    % 如果图像是灰度图，确保avgSpectrum是二维的
    if size(avgSpectrum, 2) == 1
        avgSpectrum = avgSpectrum';
    end
    
    % 计算光谱的强度 (RGB通道的总和)
    intensity = sum(double(avgSpectrum), 2);
    
    % 3. 检测光谱的起止点
    % 使用梯度和阈值来检测光谱的起始和结束位置
    smoothIntensity = movmean(intensity, 5);  % 平滑处理
    gradIntensity = gradient(smoothIntensity);
    threshold = 0.1 * max(abs(gradIntensity));
    
    % 找到明显的强度变化点
    startIdx = find(abs(gradIntensity) > threshold, 1, 'first');
    endIdx = find(abs(gradIntensity) > threshold, 1, 'last');
    
    % 如果自动检测失败，则使用整个区域
    if isempty(startIdx) || isempty(endIdx) || startIdx >= endIdx
        startIdx = 1;
        endIdx = length(intensity);
    end
    
    % 显示检测到的光谱强度和起止点
    figure('Name', '光谱强度与边界检测', 'NumberTitle', 'off');
    plot(intensity);
    hold on;
    plot([startIdx startIdx], [min(intensity) max(intensity)], 'r--', 'LineWidth', 2);
    plot([endIdx endIdx], [min(intensity) max(intensity)], 'r--', 'LineWidth', 2);
    title('光谱强度与检测的边界');
    xlabel('像素位置');
    ylabel('强度');
    hold off;
    
    % 4. 转换为标准光谱坐标
    % 假设标准可见光谱为380nm-750nm
    lambdaMin = 380; % nm
    lambdaMax = 750; % nm
    
    % 将像素位置映射到波长
    lambda = linspace(lambdaMin, lambdaMax, endIdx - startIdx + 1);
    
    % 提取对应区域的RGB值
    R = double(avgSpectrum(startIdx:endIdx, 1));
    G = double(avgSpectrum(startIdx:endIdx, 2));
    B = double(avgSpectrum(startIdx:endIdx, 3));
    
    % 5. 绘制最终的光谱图
    figure('Name', '转换后的光谱', 'NumberTitle', 'off');
    
    % 创建子图
    subplot(2, 1, 1);
    % 绘制RGB分量
    plot(lambda, R, 'r', 'LineWidth', 1.5);
    hold on;
    plot(lambda, G, 'g', 'LineWidth', 1.5);
    plot(lambda, B, 'b', 'LineWidth', 1.5);
    title('RGB分量');
    xlabel('波长 (nm)');
    ylabel('强度');
    legend('红', '绿', '蓝');
    grid on;
    
    subplot(2, 1, 2);
    % 绘制总强度
    plot(lambda, R+G+B, 'k', 'LineWidth', 2);
    title('总强度');
    xlabel('波长 (nm)');
    ylabel('强度');
    grid on;
    
    % 6. 显示彩色光谱可视化
    figure('Name', '彩色光谱可视化', 'NumberTitle', 'off');
    
    % 创建彩色条带来表示波长
    colorBarHeight = 50;
    colorBar = zeros(colorBarHeight, length(lambda), 3);
    
    % 为每个波长分配一个大致的RGB颜色
    for i = 1:length(lambda)
        wavelength = lambda(i);
        rgb = wavelengthToRGB(wavelength);
        
        for j = 1:colorBarHeight
            colorBar(j, i, :) = rgb;
        end
    end
    
    % 显示彩色光谱条和对应的强度曲线
    subplot(2, 1, 1);
    imshow(colorBar);
    title('波长颜色对应');
    
    subplot(2, 1, 2);
    plot(lambda, R+G+B, 'k', 'LineWidth', 2);
    title('光谱强度');
    xlabel('波长 (nm)');
    ylabel('强度');
    xlim([min(lambda), max(lambda)]);
    grid on;
    
    % 导出结果
    spectralData = table(lambda', R, G, B, R+G+B, 'VariableNames', {'Wavelength', 'Red', 'Green', 'Blue', 'TotalIntensity'});
    writetable(spectralData, 'extracted_spectrum.csv');
    disp('光谱数据已保存到 extracted_spectrum.csv');
end

% 辅助函数：将波长转换为RGB颜色表示
function rgb = wavelengthToRGB(wavelength)
    % 这是一个简化的波长到RGB的转换函数
    % 基于可见光谱的近似
    
    if wavelength >= 380 && wavelength < 440
        % 紫色到蓝色
        r = (440 - wavelength) / (440 - 380);
        g = 0;
        b = 1;
    elseif wavelength >= 440 && wavelength < 490
        % 蓝色到青色
        r = 0;
        g = (wavelength - 440) / (490 - 440);
        b = 1;
    elseif wavelength >= 490 && wavelength < 510
        % 青色到绿色
        r = 0;
        g = 1;
        b = (510 - wavelength) / (510 - 490);
    elseif wavelength >= 510 && wavelength < 580
        % 绿色到黄色
        r = (wavelength - 510) / (580 - 510);
        g = 1;
        b = 0;
    elseif wavelength >= 580 && wavelength < 645
        % 黄色到橙色
        r = 1;
        g = (645 - wavelength) / (645 - 580);
        b = 0;
    elseif wavelength >= 645 && wavelength <= 750
        % 橙色到红色
        r = 1;
        g = 0;
        b = 0;
    else
        % 可见光谱外
        r = 0;
        g = 0;
        b = 0;
    end
    
    % 亮度调整
    factor = 0.8;
    if wavelength >= 380 && wavelength < 420
        factor = 0.3 + 0.7 * (wavelength - 380) / (420 - 380);
    elseif wavelength >= 650
        factor = 0.3 + 0.7 * (750 - wavelength) / (750 - 650);
    end
    
    rgb = [r, g, b] * factor;
end