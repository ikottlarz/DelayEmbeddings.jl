#####################################################################################
#                   Neighborhood.jl Interface & convenience functions               #
#####################################################################################
using Neighborhood, Distances

export WithinRange, NeighborNumber
export Euclidean, Chebyshev, Cityblock

Neighborhood.KDTree(D::AbstractDataset, metric::Metric = Euclidean(); kwargs...) =
KDTree(D.data, metric; kwargs...)

# Convenience extensions for ::Dataset in bulksearches
for f ∈ (:bulkisearch, :bulksearch)
    for nt ∈ (:NeighborNumber, :WithinRange)
        @eval Neighborhood.$(f)(ss::KDTree, D::AbstractDataset, st::$nt, args...; kwargs...) =
        $(f)(ss, D.data, st, args...; kwargs...)
    end
end

#=
    all_neighbors(vtree, vs, ns, K, w)
Return the `maximum(K)`-th nearest neighbors for all input points `vs`,
with indices `ns` in original data, while respecting the theiler window `w`.

This function is nothing more than a convinience call to `Neighborhood.bulksearch`.

It is internal, convenience function.
=#
function all_neighbors(vtree, vs, ns, K, w)
    w ≥ length(vtree.data)-1 && error("Theiler window larger than the entire data span!")
    k = maximum(K)
    tw = Theiler(w, ns)
    idxs, dists = bulksearch(vtree, vs, NeighborNumber(k), tw)
end

"""
    all_neighbors(A::Dataset, stype, w = 0) → idxs, dists
Find the neighbors of all points in `A` using search type `stype` (either
[`NeighborNumber`](@ref) or [`WithinRange`](@ref)) and `w` the [Theiler window](@ref).

This function is nothing more than a convinience call to `Neighborhood.bulksearch`.
"""
function all_neighbors(A::AbstractDataset, stype, w::Int = 0)
    theiler = Theiler(w)
    tree = KDTree(A)
    idxs, dists = bulksearch(tree, A, stype, theiler)
end

#####################################################################################
#                Old Neighborhood Interface, deprecated                             #
#####################################################################################
import NearestNeighbors
using StaticArrays
using Distances: Euclidean, Metric

export AbstractNeighborhood
export FixedMassNeighborhood, FixedSizeNeighborhood
export neighborhood, KDTree

"""
    AbstractNeighborhood
Supertype of methods for deciding the neighborhood of points for a given point.

Concrete subtypes:
* `FixedMassNeighborhood(K::Int)` :
  The neighborhood of a point consists of the `K`
  nearest neighbors of the point.
* `FixedSizeNeighborhood(ε::Real)` :
  The neighborhood of a point consists of all
  neighbors that have distance < `ε` from the point.

See [`neighborhood`](@ref) for more.
"""
abstract type AbstractNeighborhood end

struct FixedMassNeighborhood <: AbstractNeighborhood
    K::Int
    function FixedMassNeighborhood(k::Int = 1)
        @warn "FixedMassNeighborhood is deprecated in favor of NeighborNumber."
        return new(k)
    end
end

struct FixedSizeNeighborhood <: AbstractNeighborhood
    ε::Float64
    function FixedSizeNeighborhood(ε::Real = 0.01)
        @warn "FixedSizeNeighborhood is deprecated in favor of WithinRange."
        return new(ε)
    end
end

"""
    neighborhood(point, tree, ntype)
    neighborhood(point, tree, ntype, n::Int, w::Int = 1)

Return a vector of indices which are the neighborhood of `point` in some
`data`, where the `tree` was created using `tree = KDTree(data [, metric])`.
The `ntype` is the type of neighborhood and can be any subtype
of [`AbstractNeighborhood`](@ref).

Use the second method when the `point` belongs in the data,
i.e. `point = data[n]`. Then `w` stands for the Theiler window (positive integer).
Only points that have index
`abs(i - n) ≥ w` are returned as a neighborhood, to exclude close temporal neighbors.
The default `w=1` is the case of excluding the `point` itself.

## References

`neighborhood` simply interfaces the functions
`NearestNeighbors.knn` and `inrange` from
[NearestNeighbors.jl](https://github.com/KristofferC/NearestNeighbors.jl) by using
the argument `ntype`.
"""
function neighborhood(point::AbstractVector, tree,
                      ntype::FixedMassNeighborhood, n::Int, w::Int = 1)
    @warn "`neighborhood` is deprecated in favor of using `search` and Neighborhood.jl."
    idxs, = NearestNeighbors.knn(tree, point, ntype.K, false, i -> abs(i-n) < w)
    return idxs
end
function neighborhood(point::AbstractVector, tree, ntype::FixedMassNeighborhood)
    @warn "`neighborhood` is deprecated in favor of using `search` and Neighborhood.jl."
    idxs, = NearestNeighbors.knn(tree, point, ntype.K, false)
    return idxs
end

function neighborhood(point::AbstractVector, tree,
                      ntype::FixedSizeNeighborhood, n::Int, w::Int = 1)

@warn "`neighborhood` is deprecated in favor of using `search` and Neighborhood.jl."
    idxs = NearestNeighbors.inrange(tree, point, ntype.ε)
    filter!((el) -> abs(el - n) ≥ w, idxs)
    return idxs
end
function neighborhood(point::AbstractVector, tree, ntype::FixedSizeNeighborhood)
    @warn "`neighborhood` is deprecated in favor of using `search` and Neighborhood.jl."
    idxs = NearestNeighbors.inrange(tree, point, ntype.ε)
    return idxs
end
