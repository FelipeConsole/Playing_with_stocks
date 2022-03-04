``` Julia Lang

Análise ingênua de algumas ações listadas na B3.

Montamos a carteira selecionando algumas ações e consideramos um período fixo (digamos, 1 ano).
Criamos o retorno simples dessa carteira, baseado na variação de um dia pro outro do valor de fechamento.
Por fim, visualisamos a combinação que miniza o risco da carteira.
```
# pacotes necessários
using  Plots, PyCall, Colors, Distributions

# pegando algumas as ações de interesse
acoes = ["MGLU3.SA","AZUL4.SA", "PETR4.SA"] |> sort

# Usando os pacotes yfinance e pandas do Python,
# pra isso precisamos chamar o Python com o pkg Pycall, usando a função pyimport.  
pd=pyimport("pandas")
yf=pyimport("yfinance")

# pegamos apenas os valores de fechamento das ações no último ano.
data=yf.download(;tickers=acoes,period="1y",group_by="column")[:Close].values
data=reshape(data,size(data, 1), :)



# Para melhor visualizar, vamos usar o pacote de cores colors
# e preparar alguns argumentos para plotar
colors = Colors.distinguishable_colors(length(acoes), [RGB(1,1,1), RGB(0,0,0)], dropseed=true)
colors=reshape(colors, 1, :)
labels = reshape(acoes, 1, :)
plt_args = (:leg => :topleft, :lab => labels, :c => colors)


# Série temporal das açoes escolhidas
plot(data;plt_args... )


# retorno simples do valor de fechamento, dia seguinte menos o dia anterior, normalizado
retornos = (data[2:end,:] - data[1:end-1,:])./data[1:end-1,:]

# visualização dos retornos simples
plot(retornos;plt_args...)





# média e variância das acões
μM = reshape(mean(retornos, dims=1),:,1 )
σM = cov(retornos)
# visualizando com histograma os retornos
histogram(retornos, bins=50, normalize=true, opacity = 0.5; plt_args...)
#  Fitando uma normal pra cada ação com as respectivas médias e variâncias
for i = 1:length(acoes)
	d = Normal(μM[i], sqrt(σM[i,i]))
	plot!(x -> pdf(d, x), μM[i]-3*sqrt(σM[i,i]) , μM[i]+3*sqrt(σM[i,i]), lw=3; c=colors[i],lab = "")
end
plot!() 


using LinearAlgebra
x1 = 0.5
x2 = 0.2
x3 = 0.1
x = [x1; x2]
x = [x; 1-sum(x)]
if x[end] ≥ 0   
	cart_ret = retornos * x
	cart_val = [1.0;cumprod(1 .+ cart_ret)]

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
	# for θ = range(0,1,length=50)
	# 	xθ = [θ;1-θ]
	# 	push!(μθ,dot(μM,xθ) )
	# 	push!(σθ,xθ'*σM*xθ)
	# end
	plot!(plt[1,2],μθ,σθ,c=:black,lab="")
	plot!(plt[2,1],cart_val,c=:black,lab="",lw = 3)
	plot!(plt[2,1],data ./ data[1,:]';plt_args...)

	plot!(plt[2,2],cart_ret,c=:black,lab="cart")
	plot!(plt[2,2],retornos; plt_args...)


	plt
end


# plot(data./ data[1,:]' ; plt_args... )
