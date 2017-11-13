%% ²âÊÔYALMIP
blues = randn(2,25);
greens = randn(2,25)+2;
a = sdpvar(2,1);
b = sdpvar(1);
u = sdpvar(1,25);
v = sdpvar(1,25);
Constraints = [a'*greens+b >= 1-u, a'*blues+b <= -(1-v), u >= 0, v >= 0]
Objective = sum(u)+sum(v)
Constraints = [Constraints, -1 <= a <= 1];
Ops = sdpsettings('verbose',0,'solver','mosek');
results=optimize(Constraints,Objective,Ops)
x = sdpvar(2,1);
P1 = [-5<=x<=5, value(a)'*x+value(b)>=0];
P2 = [-5<=x<=5, value(a)'*x+value(b)<=0];
clf