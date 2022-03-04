### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ d5de4632-1cb4-11ec-0f71-211bc21903b7
using PlutoUI, Plots, PyCall, Colors, Distributions

# ╔═╡ 949f8915-0c07-4192-9b2a-2a0e711df057
begin
	acoes = ["MGLU3.SA","AZUL4.SA"] |> sort

	pd=pyimport("pandas")
	yf=pyimport("yfinance")
	data=yf.download(;tickers=acoes,period="1y",group_by="column")[:Close].values
	data=reshape(data,size(data, 1), :)
end

# ╔═╡ ba4b6c5f-b64b-4713-b9ef-dd539df5d337
begin
	colors = Colors.distinguishable_colors(length(acoes), [RGB(1,1,1), RGB(0,0,0)], dropseed=true)
	colors=reshape(colors, 1, :)
	labels = reshape(acoes, 1, :)
	plt_args = (:leg => :topleft, :lab => labels, :c => colors)
end

# ╔═╡ f03c9391-ee1e-454c-894a-086974e4c366
plot(data;plt_args... )

# ╔═╡ 5db5e4e3-e705-4afc-b430-26dd2ebfdd9f
retornos = (data[2:end,:] - data[1:end-1,:])./data[1:end-1,:]

# ╔═╡ 52dfd2ee-b177-4732-b8c8-39626957b1fe
plot(retornos;plt_args...)

# ╔═╡ 37904f55-6197-4995-a6c1-bf20faaa5248


# ╔═╡ cf5f6a52-f931-48ae-b4d3-5186d9efd3bc
md"""
parace? distribuição normla?
"""

# ╔═╡ 8f56c1cd-802d-4d01-95c5-3335dc129737
begin
	μM = reshape(mean(retornos, dims=1),:,1 )
	σM = cov(retornos)
	histogram(retornos, bins=50, normalize=true, opacity = 0.5; plt_args...)
	for i = 1:length(acoes)
		d = Normal(μM[i], sqrt(σM[i,i]))
		plot!(x -> pdf(d, x), μM[i]-3*sqrt(σM[i,i]) , μM[i]+3*sqrt(σM[i,i]), lw=3; c=colors[i],lab = "")
	end
	plot!() 
	  
end

# ╔═╡ d2dba16f-642e-4350-9159-eca0b2d48e05
md"""
combinação linear de ações  e minimizar o 'risco'
"""

# ╔═╡ 2636a0bf-ed26-46d0-a7bf-d80ebc0a4c16
md"""
x₁	= $(@bind x₁ Slider(0:0.05:1,show_value=true))
"""

# ╔═╡ 42646a1b-3025-4b5d-945f-627cde77160c
begin
	using LinearAlgebra
	x = [x₁]
	x = [x;1-sum(x)]
	if x[end] ≥ 0  
		cart_ret = retornos * x
		cart_val = [1;cumprod(1 .+ cart_ret)]

		μ = mean(cart_ret)
		σ = std(cart_ret)

		plt = plot(layout=grid(2,2),size = (600,600))
		for i = 1:length(acoes)
			μᵢ = μM[i]
			σᵢ = sqrt(σM[i,i])
			d = Normal(μᵢ, σᵢ)
			plot!(plt[1,1], x -> pdf(d, x), μᵢ-3σᵢ, μᵢ+3σᵢ, lw=3; c=colors[i], lab =labels[i])
			plot!(plt[1,1], [μᵢ,μᵢ],[0,pdf(d,μᵢ)],c=colors[i],lab="")
			plot!(plt[1,1], [μᵢ-σᵢ,μᵢ+σᵢ],[pdf(d,μᵢ-σᵢ),pdf(d,μᵢ+σᵢ)],c=colors[i],lab="")
		end
		normal = Normal(μ,σ)
		plot!(plt[1,1],x ->pdf(normal,x),μ-3σ,μ+3σ,lw=3,c=:black,lab="cart" )
		plot!(plt[1,1],[μ,μ],[0,pdf(normal,μ)],c=:black,lab="")
		plot!(plt[1,1],[μ-σ,μ+σ],[pdf(normal,μ-σ),pdf(normal,μ+σ)],c=:black,lab="")

		#valores das médias e variâncias
		scatter!(plt[1,2], μM',diag(σM)', xlabel = "retorno", ylabel = "risco"; plt_args...)
		scatter!(plt[1,2], [μ],[σ^2], c =:black, leg=false)
		μθ = []
		σθ = []
		for θ = range(0,1,length=50)
			xθ = [θ;1-θ]
			push!(μθ,dot(μM,xθ) )
			push!(σθ,xθ'*σM*xθ)
		end
		plot!(plt[1,2],μθ,σθ,c=:black,lab="")
		plot!(plt[2,1],cart_val,c=:black,lab="",lw = 3)
		plot!(plt[2,1],data ./ data[1,:]';plt_args...)

		plot!(plt[2,2],cart_ret,c=:black,lab="cart")
		plot!(plt[2,2],retornos; plt_args...)


		plt
	end
end

# ╔═╡ c56192d4-c8ac-484c-9cec-02adc480dc46
plot(data./ data[1,:]' ; plt_args... )
