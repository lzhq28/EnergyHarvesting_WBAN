function P_tran = tranMatrix(P_ini,P_state)
%tranMatrix :给定各个阶段的稳定概率，计算状态转移矩阵

% 用户是否是想获得：Pij表示由状态i转移到j的概率
    changeState = 0;
    if size(P_state,1)==1
        changeState = 1;
        P_state = P_state';
    end 
% 通过推到公式获得稳定的状态转移矩阵
    P_tran=P_ini+(eye(size(P_ini,1))-P_ini)*P_state*pinv(P_state);
    if(size(P_tran(P_tran<0),1)==0)
        disp('Success：obtain the transit matrix.')
    end
%  用户是否是想获得：Pij表示由状态i转移到j的概率
    if changeState ==1
        P_tran = P_tran';
    end
end

