function P_tran = tranMatrix(P_state)
%tranMatrix :���������׶ε��ȶ����ʣ�����״̬ת�ƾ���

% ��ʼ��״̬ת�ƾ���Pij��ʾ״̬��jת�Ƶ�i�ĸ���
    P_ini=[0.7,0.5,0.5;
           0.15,0.3,0.2;
           0.15,0.2,0.3;];
% �û��Ƿ������ã�Pij��ʾ��״̬iת�Ƶ�j�ĸ���
    changeState = 0;
    if size(P_state,1)==1
        changeState = 1;
        P_state = P_state';
    end 
% ͨ���Ƶ���ʽ����ȶ���״̬ת�ƾ���
    P_tran=P_ini+(eye(size(P_ini,1))-P_ini)*P_state*pinv(P_state);
    if(size(P_tran(P_tran<0),1)==0)
        disp('Success��obtain the transit matrix.')
    end
%  �û��Ƿ������ã�Pij��ʾ��״̬iת�Ƶ�j�ĸ���
    if changeState ==1
        P_tran = P_tran';
    end
end

