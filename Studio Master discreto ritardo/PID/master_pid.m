Mm = 0.64;
Bm = 12;

s = tf('s');

A = [0 1; 0 -Bm/Mm];
B = [0; 1/Mm];
C = [1 0; 0 1];
D = [0; 0];
C0 = [1 10];
B0 = [0; 1/Mm];

K = [5 5];