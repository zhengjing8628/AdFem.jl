module AdFem 

    using SparseArrays
    using LinearAlgebra
    using PyCall
    using PyPlot
    using Parameters
    using Reexport
    using Statistics
    using MAT
    @reexport using ADCME

    pts = @. ([-1/sqrt(3); 1/sqrt(3)] + 1)/2
    np = PyNULL()
    LIBMFEM = abspath(joinpath(@__DIR__, "..",  "deps", "MFEM", "build", get_library_name("admfem")))
    libmfem = missing 
    LIBADFEM = abspath(joinpath(@__DIR__, "..",  "deps", "build", get_library_name("adfem")))
    libadfem = missing

    function __init__()
        copy!(np, pyimport("numpy"))
        if !isfile(LIBMFEM) || !isfile(LIBADFEM)
            error("Dependencies of AdFem not properly built. Run `Pkg.build(\"AdFem\")` to rebuild AdFem.")
        end
        global libmfem = load_library(LIBMFEM)
        global libadfem = load_library(LIBADFEM)
    end

    include("Struct.jl")
    include("Utils.jl")
    include("Core.jl")
    include("Plasticity.jl")
    include("InvCore.jl")
    include("Viscoelasticity.jl")
    include("Visualization.jl")
    include("Constitutive.jl")
    include("Solver.jl")
    include("MFEM/MFEM.jl")
    include("MFEM/MCore.jl")
    include("MFEM/MVisualize.jl")
    include("MFEM/MUtils.jl")
    include("MFEM/Mechanics.jl")
    include("MFEM/MBDM.jl")

end