function [ path_names ] = configurePaths()
%configurePaths ��������ļ���·��
    path_names.data_fold = './data/';
    path_names.miu_th = strcat(path_names.data_fold,'miu_parameter.mat');
    path_names.save_prefix = strcat(path_names.data_fold,'QoS_Queue_deltaPL-'); %�������ܵ�·��ǰ׺
end

