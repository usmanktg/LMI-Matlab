Mm = 0.64;
Bm = 12;

A = [0 1; 0 -Bm/Mm];
B = [0; 1/Mm];
C = [1 0; 0 1];
D = [0; 0];
B0 = [0; 1/Mm];
D0 = [0];
C0 = [0 10];

Ts = 0.001;
mu = 1;

csys = ss(A,B,C,D);
dsys = c2d(csys, Ts);

n_delay = 5;
phi = dsys.a;
gamma1 = dsys.b;
gamma2 = zeros(size(dsys.b,1), size(dsys.b,2));

Az1 = [phi gamma1 gamma2 zeros(size(dsys.b,1), n_delay-1)];
Az21 = [zeros(n_delay+1,size(dsys.a,2)+size(dsys.b,2))];
Az22 = [eye(n_delay+1,n_delay)];

A_z = [Az1; Az21 Az22];

B_z=[zeros(size(A_z,1)-1,1); 1]
C_z=[dsys.c zeros(size(dsys.c,1),n_delay+1)]

A_nodelay = dsys.a;
B_nodelay  = dsys.b;
C_nodelay  = dsys.c;
D_nodelay  = dsys.d;

%A = A_z;
%Bu = B_z;
%Bw = B_z;
%Cy = C_z;
%Dyw = dsys.d;
%Cz = [0 10 zeros(1, size(A,2)-2)];
%Dzw = [zeros(size(Bu,2))];
%Dzu = [zeros(size(Bu,2))];

A = A_nodelay;
Bu = B_nodelay;
Bw = B_nodelay;
Cy = [1 0];
Dyw = 0;
Cz = [1 0];
Dzw = 0;
Dzu = 0;


dsys_delay = ss(A, Bu, Cy, 0, Ts);

n = size(A,1);
p = size(Bu,1);
q = size(Bu,2);
r = size(Dyw,1);
s = size(Dyw,2);
t = size(Cy,1);
u = size(Cy,2);

P = sdpvar(n,n, 'symmetric');
H = sdpvar(n,n, 'symmetric');
L = sdpvar(q,n);
F = sdpvar(n,t); 
Q = sdpvar(n,n); 
R = sdpvar(q,t);
S = sdpvar(n,n); 
J = sdpvar(n,n); 
X = sdpvar(n,n);
Y = sdpvar(n,n); 

b11 = P;
b12 = J;
b13 = A*X+Bu*L;
b14 = A+Bu*R*Cy;
b15 = Bw+Bu*R*Dyw;
b16 = zeros(n,q);

bb1 = [b11 b12 b13 b14 b15 b16];

b21 = b12';
b22 = H;
b23 = Q;
b24 = Y*A+F*Cy;
b25 = Y*Bw+F*Dyw;
b26 = zeros(n,q);

bb2 = [b21 b22 b23 b24 b25 b26];

b31 = b13';
b32 = b23';
b33 = X+X'-P;
b34 = eye(n,n)+S'-J;
b35 = zeros(n,q);
b36 = X'*Cz'+L'*Dzu';

bb3 = [b31 b32 b33 b34 b35 b36];

b41 = b14';
b42 = b24';
b43 = b34';
b44 = Y+Y'-H;
b45 = zeros(n,q);
b46 = Cz'+Cy'*R'*Dzu';

bb4 = [b41 b42 b43 b44 b45 b46];

b51 = b15';
b52 = b25';
b53 = b35';
b54 = b45';
b55 = eye(q,q);
b56 = Dzw'+Dyw'*R'*Dzu';

bb5 = [b51 b52 b53 b54 b55 b56];

b61 = b16';
b62 = b26';
b63 = b36';
b64 = b46';
b65 = b56';
b66 = mu*eye(q,q);

bb6 = [b61 b62 b63 b64 b65 b66];

LMI = [bb1; bb2; bb3; bb4; bb5; bb6];

res = [X >= 0, Y >= 0, S >= 0, R >= 0, LMI >=0];

diagnostics = solvesdp(res);
disp(diagnostics.problem);
if diagnostics.problem == 0
 disp('Feasible')

 [U,V] = qr(-value(Y)*value(X)+eye(size(value(Y)*value(X))));
 m12 = -inv(V)*value(Y)*Bu;
 mat1 = [inv(V) m12; zeros(size(Bu,2),n) eye(size(Bu,2))];
 mat2 = [value(Q)-value(Y)*A*value(X) value(F); value(L) value(R)];
 mat3 = [inv(value(U)) zeros(n,size(Cy,1)); -Cy*value(X)*inv(value(U)) eye(size(Cy,1))];
 K = mat1*mat2*mat3;

 %state space realization of the controller
 Ac = K(1:n,1:n);
 Bc = K(1:n,n+1:end);
 Cc = K(n+1:end,1:n);
 Dc = K(end,end);

elseif diagnostics.problem == 1
 disp('Infeasible')
else
 disp('Something else happened')
end
