using AdFem
using PyPlot
using SparseArrays

function f1func(x,y)
    18.8495559215388*pi^2*sin(pi*x)^2*sin(pi*y)*cos(pi*y) - 6.28318530717959*pi^2*sin(pi*y)*cos(pi*x)^2*cos(pi*y) + pi*sin(pi*y)*cos(pi*x)
end
function f2func(x,y)
    -18.8495559215388*pi^2*sin(pi*x)*sin(pi*y)^2*cos(pi*x) + 6.28318530717959*pi^2*sin(pi*x)*cos(pi*x)*cos(pi*y)^2 + pi*sin(pi*x)*cos(pi*y)
end


m = 50
n = 50
h = 1/n
mmesh = Mesh(m, n, h, degree=2)
ν = 0.5
K = ν*constant(compute_fem_laplace_matrix(mmesh))
B = constant(compute_interaction_matrix(mmesh))
Z = [K -B'
    -B spzero(size(B,1))]

bd = bcnode(mmesh)
bd = [bd; bd .+ mmesh.ndof; 2mmesh.ndof + 1]

F1 = eval_f_on_gauss_pts(f1func, mmesh)
F2 = eval_f_on_gauss_pts(f2func, mmesh)
F = compute_fem_source_term(F1, F2, mmesh)
rhs = [F;zeros(mmesh.nelem)]
Z, rhs = impose_Dirichlet_boundary_conditions(Z, rhs, bd, zeros(length(bd)))
sol = Z\rhs 

sess = Session(); init(sess)
S = run(sess, sol)

xy = fem_nodes(mmesh)
x, y = xy[:,1], xy[:,2]
U = @. 2*pi*sin(pi*x)*sin(pi*x)*cos(pi*y)*sin(pi*y)
figure(figsize=(12,5))
subplot(121)
visualize_scalar_on_fem_points(U, mmesh)
title("Reference")
subplot(122)
visualize_scalar_on_fem_points(S[1:mmesh.nnode], mmesh)
title("Computed")
savefig("stokes1.png")

U = @. -2*pi*sin(pi*x)*sin(pi*y)*cos(pi*x)*sin(pi*y)
figure(figsize=(12,5))
subplot(121)
visualize_scalar_on_fem_points(U, mmesh)
title("Reference")
subplot(122)
visualize_scalar_on_fem_points(S[mmesh.ndof+1:mmesh.ndof+mmesh.nnode], mmesh)
title("Computed")
savefig("stokes2.png")


xy = fvm_nodes(mmesh)
x, y = xy[:,1], xy[:,2]
p = @. sin(pi*x)*sin(pi*y)
figure(figsize=(12,5))
subplot(121)
visualize_scalar_on_fvm_points(p, mmesh)
title("Reference")
subplot(122)
visualize_scalar_on_fvm_points(S[2mmesh.ndof+1:end], mmesh)
title("Computed")
savefig("stokes3.png")