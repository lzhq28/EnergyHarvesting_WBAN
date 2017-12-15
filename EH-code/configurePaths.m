function [ path_names ] = configurePaths(t_cor_EH)
%configurePaths 配置相关文件的路径
    path_names.data_fold = './data/';
    path_names.miu_th = strcat(path_names.data_fold,'miu_parameter.mat');
    path_names.myRA_prefix = strcat(path_names.data_fold,'myRA_QoS_Queue_CorTime-',num2str(t_cor_EH),'ms_deltaPL-'); %保存性能的路径前缀
    path_names.offline_prefix = strcat(path_names.data_fold,'Offline_QoS_Queue_CorTime-',num2str(t_cor_EH),'ms_deltaPL-'); %保存性能的路径前缀
    path_names.online_prefix =  strcat(path_names.data_fold,'Online_QoS_Queue_CorTime-',num2str(t_cor_EH),'ms_deltaPL-'); %保存性能的路径前缀
    path_names.fixed_prefix =  strcat(path_names.data_fold,'Fixed_QoS_Queue_CorTime-',num2str(t_cor_EH),'ms_deltaPL-'); %保存性能的路径前缀
end

