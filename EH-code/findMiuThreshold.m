function [ miu_th ] = findMiuThreshold(sigma, packet_length, PLR_th, Channel, precision)
%findMiuThreshold 给定丢包率阈值下的平均信噪比
% sigma 阴影衰落的标准差
% packet_length 数据包的长度，单位bit
% PLR_th 丢包率门限值
% precision 要达到的精度范围
    disp(['********** (sigma,PLR_th):',num2str(sigma),',',num2str(PLR_th),'**********'])
    %% 配置参数
    miu_dB_min = 0;%初始化最小miu_dB，单位dB
    miu_dB_max = 20;%初始化最大miu_dB，单位dB
    %首先判断左右边界是否需要扩展
    while 1
        [PLR_ave,P_sum] = calAvePLR(sigma, miu_dB_max, packet_length, Channel.BCH_n); %计算平局丢包率
        if(PLR_ave>PLR_th) %需要扩展右边界
            miu_dB_max = miu_dB_max*2;
        else
            break;
        end
    end
    while 1
        [PLR_ave,P_sum] = calAvePLR(sigma, miu_dB_min, packet_length, Channel.BCH_n); %计算平局丢包率
        if(PLR_ave<PLR_th) %需要减小左边界
            miu_dB_min = miu_dB_min - 10;
        else
            break;
        end
    end
    %% 使用二分法进行平均比特信噪比的门限值miu_th
    left = miu_dB_min; 
    right = miu_dB_max;
    while 1
        mid = (left+right)/2;
        [PLR_ave,P_sum] = calAvePLR(sigma, mid, packet_length, Channel.BCH_n); %计算平局丢包率
        delta_PLR = PLR_ave - PLR_th;
        disp(['(left,mid,right):',num2str(left),':',num2str(mid),';',num2str(right),',PLR-PLR_th:',num2str(delta_PLR),',P_sum:',num2str(P_sum),',PLR_ave:',num2str(PLR_ave)])
        if(abs(delta_PLR)<=precision)
            miu_th = mid;
            return;
        else
            if(delta_PLR>0)
                left = mid;
            else
                right = mid;
            end
        end
    end
end

