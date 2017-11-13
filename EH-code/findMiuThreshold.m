function [ miu_th ] = findMiuThreshold(sigma, packet_length, PLR_th, Channel, precision)
%findMiuThreshold ������������ֵ�µ�ƽ�������
% sigma ��Ӱ˥��ı�׼��
% packet_length ���ݰ��ĳ��ȣ���λbit
% PLR_th ����������ֵ
% precision Ҫ�ﵽ�ľ��ȷ�Χ
    disp(['********** (sigma,PLR_th):',num2str(sigma),',',num2str(PLR_th),'**********'])
    %% ���ò���
    miu_dB_min = 0;%��ʼ����Сmiu_dB����λdB
    miu_dB_max = 20;%��ʼ�����miu_dB����λdB
    %�����ж����ұ߽��Ƿ���Ҫ��չ
    while 1
        [PLR_ave,P_sum] = calAvePLR(sigma, miu_dB_max, packet_length, Channel.BCH_n); %����ƽ�ֶ�����
        if(PLR_ave>PLR_th) %��Ҫ��չ�ұ߽�
            miu_dB_max = miu_dB_max*2;
        else
            break;
        end
    end
    while 1
        [PLR_ave,P_sum] = calAvePLR(sigma, miu_dB_min, packet_length, Channel.BCH_n); %����ƽ�ֶ�����
        if(PLR_ave<PLR_th) %��Ҫ��С��߽�
            miu_dB_min = miu_dB_min - 10;
        else
            break;
        end
    end
    %% ʹ�ö��ַ�����ƽ����������ȵ�����ֵmiu_th
    left = miu_dB_min; 
    right = miu_dB_max;
    while 1
        mid = (left+right)/2;
        [PLR_ave,P_sum] = calAvePLR(sigma, mid, packet_length, Channel.BCH_n); %����ƽ�ֶ�����
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

