module ArrayAssemblers

export block, lolcat, lay

"""
    block(array_of_arrays)

Concatenates a multi-dimensional array of arrays into a single array, seeing
the input as a block array. The dimensions of the sub-arrays must match accordingly.

# Examples

Simple concatenation of vectors

```jldoctest
julia> reduce(hcat, [[1,2,3], [4,5,6]])
3×2 Matrix{Int64}:
 1  4
 2  5
 3  6

julia> block(reshape([[1,2,3], [4,5,6]], 1, :))
6-element Vector{Int64}:
 1  4
 2  5
 3  6

julia> block([[1,2,3], [4,5,6]])
6-element Vector{Int64}:
 1
 2
 3
 4
 5
 6

julia> vcat([1,2,3]', [4,5,6]')
3×2 Matrix{Int64}:
 1  2  3
 4  5  6

julia> block([[1,2,3]', [4,5,6]'])
2×3 Matrix{Int64}:
 1  2  3
 4  5  6

julia> block([[1,2,3], [4,5,6]]')
1×6 Matrix{Int64}:
 1  2  3  4  5  6
```

"Flatmap" behavior.
```jldoctest
julia> block(n -> -n:2:n, 1:3)
9-element Vector{Int64}:
 -1
  1
 -2
  0
  2
 -3
 -1
  1
  3
```

Image montage.

```
using TestImages, ImageView
myimages = ["cameraman" "plastic_bubbles_he_512" "woman_darkhair"; "resolution_test_512" "pirate" "walkbridge"]
imshow(block(testimage.(myimages)))
```

# Extended Help

## More Examples

Higher-dimension concatenation.

```jldoctest
julia> block([1 2]) do n reshape(n*4-3:n*4, 2, 2) end
2×4 Matrix{Int64}:
 1  3  5  7
 2  4  6  8

julia> block([1, 2]) do n reshape(n*4-3:n*4, 2, 2) end
4×2 Matrix{Int64}:
 1  3
 2  4
 5  7
 6  8

julia> block([1;;; 2;;;]) do n reshape(n*4-3:n*4, 2, 2) end
2×2×2 Array{Int64, 3}:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8
```

Relationship to `eachcol` and `eachrow`.

```jldoctest
julia> m = reshape(1:15,3,5)
3×5 reshape(::UnitRange{Int64}, 3, 5) with eltype Int64:
 1  4  7  10  13
 2  5  8  11  14
 3  6  9  12  15

julia> lol = eachcol(m) |> collect
5-element Vector{SubArray{Int64, 1, Base.ReshapedArray{Int64, 2, UnitRange{Int64}, Tuple{}}, Tuple{Base.Slice{Base.OneTo{Int64}}, Int64}, true}}:
 [1, 2, 3]
 [4, 5, 6]
 [7, 8, 9]
 [10, 11, 12]
 [13, 14, 15]

julia> block(lol)
15-element Vector{Int64}:
  1
  2
  3
  4
  5
  6
  7
  8
  9
 10
 11
 12
 13
 14
 15

julia> block(lol')
1×15 Matrix{Int64}:
 1  2  3  4  5  6  7  8  9  10  11  12  13  14  15

julia> block(permutedims(lol))
3×5 Matrix{Int64}:
 1  4  7  10  13
 2  5  8  11  14
 3  6  9  12  15

julia> lol = eachrow(m) |> collect
3-element Vector{SubArray{Int64, 1, Base.ReshapedArray{Int64, 2, UnitRange{Int64}, Tuple{}}, Tuple{Int64, Base.Slice{Base.OneTo{Int64}}}, true}}:
 [1, 4, 7, 10, 13]
 [2, 5, 8, 11, 14]
 [3, 6, 9, 12, 15]

julia> block(permutedims(lol))
5×3 Matrix{Int64}:
  1   2   3
  4   5   6
  7   8   9
 10  11  12
 13  14  15

julia> block(permutedims.(lol))
3×5 Matrix{Int64}:
 1  4  7  10  13
 2  5  8  11  14
 3  6  9  12  15
```

Non-uniform array shapes with 3 dimensions.

```jldoctest
julia> myarrays = map([(j,k,l) for j in 1:2, k in 1:2, l in 1:2]) do (jkl)
           reshape(1:prod((jkl)), jkl...)
       end
2×2×2 Array{Base.ReshapedArray{Int64, 3, UnitRange{Int64}, Tuple{}}, 3}:
[:, :, 1] =
 [1;;;]     [1 2;;;]
 [1; 2;;;]  [1 3; 2 4;;;]

[:, :, 2] =
 [1;;; 2]        [1 2;;; 3 4]
 [1; 2;;; 3; 4]  [1 3; 2 4;;; 5 7; 6 8]

julia> arr = block(myarrays)
3×3×3 Array{Int64, 3}:
[:, :, 1] =
 1  1  2
 1  1  3
 2  2  4

[:, :, 2] =
 1  1  2
 1  1  3
 2  2  4

[:, :, 3] =
 2  3  4
 3  5  7
 4  6  8

julia> arr == block([(j,k,l) for j in 1:2, k in 1:2, l in 1:2]) do (jkl)
           reshape(1:prod((jkl)), jkl...)
       end
true
```
"""
block(a::AbstractArray{<:AbstractArray}) = Base.hvncat(size(a), false, a...)
# block(array_of_arrays) = block_(array_of_arrays)

"""
    block(f, c...)

Equivalent to block(map(f, c...)). Implements flatmap behavior.

# Example
```jldoctest
julia> Zn = [x for n in 1:3 for x in -n:2:n]
9-element Vector{Int64}:
 -1
  1
 -2
  0
  2
 -3
 -1
  1
  3

julia> block(n -> -n:2:n, 1:3) == Zn
true
```
"""
block(f, c...) = block(map(f, c...))

# function block_(aoa; indices=(), mydim=ndims(aoa))
#     if mydim==1
#         reduce(catdim_(mydim), view(aoa,:,indices...))
#     else
#         reduce(catdim_(mydim), (block_(aoa, indices=(n, indices...), mydim=mydim-1) for n in 1:size(aoa, mydim)))
#     end
# end
# catdim_(dims) = (a,b) -> cat(a,b,dims=dims)

"""
    lolcat(list_of_lists)

Assembles a tensor of order `ndim` from a nested array-of-arrays. Vector sizes must match.

# Examples
```jldoctest
julia> lolcat([[[1,2],[3,4]], [[5,6],[7,8]]])
2×2×2 Array{Int64, 3}:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8

julia> a = eachcol(reshape(1:6,2,:))
3-element ColumnSlices{Base.ReshapedArray{Int64, 2, UnitRange{Int64}, Tuple{}}, Tuple{Base.OneTo{Int64}}, SubArray{Int64, 1, Base.ReshapedArray{Int64, 2, UnitRange{Int64}, Tuple{}}, Tuple{Base.Slice{Base.OneTo{Int64}}, Int64}, true}}:
 [1, 2]
 [3, 4]
 [5, 6]

julia> lolcat(a)
2×3 Matrix{Int64}:
 1  3  5
 2  4  6

julia> lolcat((j,k) for j in 1:4, k in 5:6) do (j,k)
                  [j, (j+k)÷2, k]
              end
3×4×2 Array{Int64, 3}:
[:, :, 1] =
 1  2  3  4
 3  3  4  4
 5  5  5  5

[:, :, 2] =
 1  2  3  4
 3  4  4  5
 6  6  6  6
```
"""
lolcat(array_of_arrays) =
    if applicable(size, array_of_arrays)
        lolcat_(array_of_arrays, outersize=size(array_of_arrays))
    else
        lolcat_(array_of_arrays)
    end
lolcat(f, c...) = lolcat(Iterators.map(f, c...))
function lolcat_(gg; myshape=(), outersize=nothing)
    head, tail = Iterators.peel(gg)
    # if dimlen == 1
    if !applicable(iterate, head) || !applicable(ndims, head) || length(head) == 1 || ndims(head) == 0
        if isnothing(outersize)
            reshape(collect(gg), myshape...,:)
        else
            reshape(collect(gg), myshape...,outersize...)
        end
    else
        lolcat_(Iterators.flatten(gg), myshape=(size(head)..., myshape..., ), outersize=outersize)
    end
end


lay(iter) = _lay(iter)

lay(f, iter) = _lay(f(x) for x in iter)
lay(f, xs, yzs...) = _lay(f(xy...) for xy in zip(xs, yzs...))
lay(f, iter; dims) = _lay(dims, f(x) for x in iter)
lay(f, xs, yzs...; dims) = _lay(dims, f(xy...) for xy in zip(xs, yzs...))

_lay(iter) = _lay(1 + ndims(first(iter)), iter)
function _lay(dims::Integer, iter)
    elsize = size(first(iter))
    newsize = (elsize[1:dims-1]..., 1, elsize[dims:end]...)
    hvncat(dims, reshape.(iter, newsize...)...)
end

# mystack(a) = hvncat(size(first(a))...,length(a))
# mystack(a) = hvncat(ndims(first(a))+1, a...)
# mystack(a) = hvncat(ndims(first(a))+1, a...)

end # module ArrayAssemblers
