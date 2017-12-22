function [ path_name ] = conPathName(t_cor_EH,deltaPL,cal_alg_id,cal_myRA_id, EH_ratio)
%% conPathName �����ļ���·��������
% ���룺
%   t_cor_EH �����ɼ����ʱ��
%   deltaPL ·�����������
%   cal_alg_id �㷨��ID��
%   cal_myRA_id �����㷨��ϸ������
%   EH_ratio �����ɼ����ʵĵȱ�������ϡ��
    path_names = configurePaths(t_cor_EH); %����·������
    if cal_alg_id == 1 %��������ķ���
        path_name = strcat([path_names.myRA_prefix{cal_myRA_id},num2str(deltaPL),'_EH-ratio-',num2str(EH_ratio),'.mat']);
    elseif cal_alg_id == 2 % offline����         
        path_name = strcat([path_names.offline_prefix,num2str(deltaPL),'_EH-ratio-',num2str(EH_ratio),'.mat']);
    elseif cal_alg_id ==3 % online����
        path_name = strcat([path_names.online_prefix,num2str(deltaPL),'_EH-ratio-',num2str(EH_ratio),'.mat']);
    elseif cal_alg_id == 4
        path_name = strcat([path_names.fixed_prefix,num2str(deltaPL),'_EH-ratio-',num2str(EH_ratio),'.mat']);
    end 
end