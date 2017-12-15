   %% 根据当前路径损耗计算满足丢包率要求的最优的功率
    function power = findPowerStaPLRth(power_min,power_max,PLR_th, tran_rate, packet_length, PL_Fr, cur_shadow, Channel, precision)      
        left = power_min;
        right = power_max;
        max_PLR = calPLR(power_min, tran_rate, packet_length, PL_Fr, cur_shadow, Channel);
        if(max_PLR<PLR_th) %最小功率满足丢包率要求
            power = power_min;% 返回最小值
            return;
        end
        min_PLR = calPLR(power_max, tran_rate, packet_length, PL_Fr, cur_shadow, Channel);
        if (min_PLR>PLR_th) %最大功率仍然不能满足丢包率要求
            power = power_max; % 返回最大值
            return;
        end
        while 1
            mid = (left+right)/2;
            tmp = calPLR(mid, tran_rate, packet_length, PL_Fr, cur_shadow, Channel);
            if(abs(tmp-PLR_th)<precision)
                power = mid;
                break;
            end
            if(tmp>PLR_th)
                left = mid;
            else
                right = mid;
            end
        end
    end