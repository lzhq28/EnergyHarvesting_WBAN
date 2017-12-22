function [ path_names ] = configurePaths(t_cor_EH)
%configurePaths 配置相关文件的路径
    path_names.data_fold = './data/';
    path_names.miu_th = strcat(path_names.data_fold,'miu_parameter.mat');
    path_names.myRA_prefix{1} = strcat(path_names.data_fold,'myRA_with-rate-slot_CorTime-',num2str(t_cor_EH),'_deltaPL-'); %保存性能的路径前缀
    path_names.myRA_prefix{2} = strcat(path_names.data_fold,'myRA_only-with-rate_CorTime-',num2str(t_cor_EH),'_deltaPL-'); %保存性能的路径前缀
    path_names.myRA_prefix{3} = strcat(path_names.data_fold,'myRA_only-with-slot_CorTime-',num2str(t_cor_EH),'_deltaPL-'); %保存性能的路径前缀
    path_names.offline_prefix = strcat(path_names.data_fold,'Offline_CorTime-',num2str(t_cor_EH),'_deltaPL-'); %保存性能的路径前缀
    path_names.online_prefix =  strcat(path_names.data_fold,'Online_CorTime-',num2str(t_cor_EH),'_deltaPL-'); %保存性能的路径前缀
    path_names.fixed_prefix =  strcat(path_names.data_fold,'Fixed_CorTime-',num2str(t_cor_EH),'_deltaPL-'); %保存性能的路径前缀
end

