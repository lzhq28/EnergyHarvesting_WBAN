   %% ���ݵ�ǰ·����ļ������㶪����Ҫ������ŵĹ���
    function power = findPowerStaPLRth(power_min,power_max,PLR_th, tran_rate, packet_length, PL_Fr, cur_shadow, Channel, precision)      
        left = power_min;
        right = power_max;
        max_PLR = calPLR(power_min, tran_rate, packet_length, PL_Fr, cur_shadow, Channel);
        if(max_PLR<PLR_th) %��С�������㶪����Ҫ��
            power = power_min;% ������Сֵ
            return;
        end
        min_PLR = calPLR(power_max, tran_rate, packet_length, PL_Fr, cur_shadow, Channel);
        if (min_PLR>PLR_th) %�������Ȼ�������㶪����Ҫ��
            power = power_max; % �������ֵ
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