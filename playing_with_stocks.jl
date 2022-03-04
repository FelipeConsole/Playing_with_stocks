
using Markdown
using InteractiveUtils

macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end


using PlutoUI, Plots, PyCall, Colors, Distributions


begin
	acoes = ["MGLU3.SA","AZUL4.SA"] |> sort

	pd=pyimport("pandas")
	yf=pyimport("yfinance")
	data=yf.download(;tickers=acoes,period="1y",group_by="column")[:Close].values
	data=reshape(data,size(data, 1), :)
end


begin
	colors = Colors.distinguishable_colors(length(acoes), [RGB(1,1,1), RGB(0,0,0)], dropseed=true)
	colors=reshape(colors, 1, :)
	labels = reshape(acoes, 1, :)
	plt_args = (:leg => :topleft, :lab => labels, :c => colors)
end


plot(data;plt_args... )


retornos = (data[2:end,:] - data[1:end-1,:])./data[1:end-1,:]


plot(retornos;plt_args...)



md"""
parace? distribuição normla?
"""


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


md"""
combinação linear de ações  e minimizar o 'risco'
"""


md"""
x₁	= $(@bind x₁ Slider(0:0.05:1,show_value=true))
"""

x₁ = 0:0.05:1

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
