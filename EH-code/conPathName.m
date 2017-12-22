function [ path_name ] = conPathName(t_cor_EH,deltaPL,cal_alg_id,cal_myRA_id, EH_ratio)
%% conPathName 配置文件的路径名配置
% 输入：
%   t_cor_EH 能量采集相干时间
%   deltaPL 路径损耗增加量
%   cal_alg_id 算法的ID号
%   cal_myRA_id 本文算法的细节配置
%   EH_ratio 能量采集速率的等比例调节稀疏
    path_names = configurePaths(t_cor_EH); %各种路径名字
    if cal_alg_id == 1 %本文提出的方法
        path_name = strcat([path_names.myRA_prefix{cal_myRA_id},num2str(deltaPL),'_EH-ratio-',num2str(EH_ratio),'.mat']);
    elseif cal_alg_id == 2 % offline方法         
        path_name = strcat([path_names.offline_prefix,num2str(deltaPL),'_EH-ratio-',num2str(EH_ratio),'.mat']);
    elseif cal_alg_id ==3 % online方法
        path_name = strcat([path_names.online_prefix,num2str(deltaPL),'_EH-ratio-',num2str(EH_ratio),'.mat']);
    elseif cal_alg_id == 4
        path_name = strcat([path_names.fixed_prefix,num2str(deltaPL),'_EH-ratio-',num2str(EH_ratio),'.mat']);
    end 
end