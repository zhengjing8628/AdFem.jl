using Revise
using ADCME
using ADCMEKit
using NNFEM 
using PyPlot
using ProgressMeter 
using Printf
using MAT
using Clustering
using JLD2

close("all")


dat = matread("data/dippingfault_viscosity_inversion.mat")
σ_ = dat["sigma"]
d_ = dat["d"]
η_ = dat["eta"]
d0 = dat["d0"]
v0 = dat["v0"]
a0 = dat["a0"]
ϵ0 = dat["epsilon0"]
σ0 = dat["sigma0"]
NT = dat["NT"]
Δt = dat["dt"]

@load "data/dippingfault_viscosity_inversion.jld2" domain
#################### Get surface observation ####################

## get surface slip
slip_idx = findall(domain.nodes[:,2] .≈ 0.0)
coords = domain.nodes[slip_idx,1]
ii = sortperm(coords)
sorted_slip_idx = slip_idx[ii]
coords = coords[ii]

########################### Inversion ###########################
# create Variable eta 
gnodes = getGaussPoints(domain)
using Random; Random.seed!(23333)
kr = kmeans(gnodes', 20)
A = kr.assignments

figure()
for i = 1:20
  scatter(gnodes[A .== i,1], gnodes[A .== i,2])
end
gca().invert_yaxis()


vs = Variable(1.5*ones(20))
ETA = constant(zeros(getNGauss(domain)))
for i = 1:20
  mask = zeros(getNGauss(domain)) 
  mask[A.==i] .= 1.0
  global ETA += vs[i] * mask 
end 
ETA *= 1e10
η = ETA 

μ = zeros(getNGauss(domain))
λ = zeros(getNGauss(domain))
k = 0
for i = 1:domain.neles
  e = domain.elements[i]
  for mat in e.mat
    global k += 1 
    μ[k] = mat.μ
    λ[k] = mat.λ
  end
end

d, v, a, σ, ϵ = ViscoelasticitySolver(
  globaldata, domain, d0, v0, a0, σ0, ϵ0, Δt, NT, μ, λ, η, Fext, ubd, abd
)

dat = matread("data/dippingfault_viscosity_inversion.mat")
d_ = dat["d"]
y_id = [sorted_slip_idx; sorted_slip_idx .+ domain.nnodes]
loss = sum((d-d_)^2)
sess = Session(); init(sess)

@show run(sess, loss)
BFGS!(sess, loss, 30)

figure(figsize=(8,3))
subplot(121)
η_est = run(sess, η[1:9:end])
visualize_scalar_on_scoped_body(η_est, zeros(domain.nnodes*2), domain)
title("Estimate")
subplot(122)
η_ref = η_[1:9:end]
visualize_scalar_on_scoped_body(η_ref, zeros(domain.nnodes*2), domain)
title("Reference")

