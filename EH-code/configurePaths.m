function [ path_names ] = configurePaths()
%configurePaths 配置相关文件的路径
    path_names.data_fold = './data/';
    path_names.miu_th = strcat(path_names.data_fold,'miu_parameter.mat');
    path_names.save_prefix = strcat(path_names.data_fold,'QoS_Queue_deltaPL-'); %保存性能的路径前缀
end

