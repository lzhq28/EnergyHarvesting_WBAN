function [PLR_ave,P_sum] = calAvePLR(sigma, miu_dB, packet_length, BCH_n)
% 计算平均丢包率
% 输入;   
%   sigma 比特信噪比的标准差
%   miu_dB 比特信噪比的平均值
%   packet_length 数据包的长度
%   BCH_n BCH编码的长度
% 输出：
%   PLR_ave 平均丢包率
%   P_sum 使用离散的方法得到的比特信噪比分布总的概率和，需要逼近1。
    [snr, snr_interval] = findSNRInterval(sigma, miu_dB, packet_length, BCH_n);
    Prb =((10/log(10))./(power(2*pi,0.5).*sigma.*snr).*exp(-power((10*log10(snr)-miu_dB),2)./(2*power(sigma,2)))); % 处于各个snr下的概率
    PLR = 1-power((1-0.5*exp(-snr)+0.5*exp(-snr).*power((1-0.5*exp(-snr)),BCH_n-1)),packet_length); %各个snr下的丢包率
    P_sum = sum(Prb.*snr_interval);
    PLR_ave = sum(Prb.*PLR.*snr_interval);
    
    function [snr, snr_interval] = findSNRInterval(sigma, miu_dB, packet_length, BCH_n)
    % 找到合适的snr间隔和最大值和最小值区间,后面该函数会放在findMiuThreshold函数中
    % 输入;   
    %   sigma 比特信噪比的标准差
    %   miu_dB 比特信噪比的平均值
    %   packet_length 数据包的长度
    %   BCH_n BCH编码的长度
    % 输出：
    %   snr 比特信噪比的离散值
    %   snr_interval 比特信噪比离散序列的间隔，用来累加计算

        snr_range = [0.00000001,0.0000001,0.000001, 0.00001, 0.0001, 0.001, 0.01,0.1, 1, 10, 50, 100, 500, 1000, 5000, 10000, 50000,100000];
        Prb =((10/log(10))./(power(2*pi,0.5).*sigma.*snr_range).*exp(-power((10*log10(snr_range)-miu_dB),2)./(2*power(sigma,2)))); % 各个snr的概率
        PLR = 1-power((1-0.5*exp(-snr_range)+0.5*exp(-snr_range).*power((1-0.5*exp(-snr_range)),BCH_n-1)),packet_length); %各个snr下的丢包率
        tmp_PLR_r = Prb;
        PLR_r_th = 10^(-40);
        ind=find(tmp_PLR_r> PLR_r_th);
        if size(ind,2)>1
            snr_min = snr_range(max(1,ind(1)-1));
            %snr_max = snr_range(min(size(snr_range,2),ind(end)+1));
            snr_max = dBm2mw(miu_dB + 4*sigma);
            if snr_max > 10000 % 这些参数都是经验值
                snr_max = 10000;
            end
            if snr_min < 0.0001 %避免snr_max太大会使得较大的运算量
                snr_interval= 0.0001;
            else
                snr_interval = 0.001;
            end
            snr = snr_min:snr_interval:snr_max;
        else
            disp('Error:snr range is not enough');
        end
    end
end 