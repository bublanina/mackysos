# -*- encoding : utf-8 -*-
class HomeController < ApplicationController

before_filter :authenticate_admin!

  def index
  	
  	if params[:datum]		#params[:datum], params[:okno_d], params[:okno_k], params[:predikcia]
  	@start = RealValue.find(params[:datum])
  	@okno_k = params[:okno_k].to_i
  	@okno_d = params[:okno_d].to_i  	
  	@alfa = params[:alfa].to_f
  	@pocet = params[:pocet].to_i
  	@vzoriek_den = RealValue.where(:cas=>@start.cas.to_date..@start.cas.to_date+1.day).count-1
  	@md_vektor = []
  	@v_vektor = []
  	@p_vektor = []
  	@start_s_oknom = RealValue.find(params[:datum].to_i-@okno_k+1) #je mozne menit casovy rozsah vzoriek
  	# do hlavneho vektora e nacita vsetky potrebne hodnoty pre vypocet
  	@e_vektor = RealValue.where(
  				:cas=>(@start_s_oknom.cas-@okno_d.to_i.days)..@start.cas+1.minute)
  	# ulozi index poslednej hodnoty
  	@posledny = @e_vektor.index(@e_vektor.last)
  	#--vypocitame vektory Md,V, P pre prve okno
  	@okno_k.times do |a|  
  		@p_vektor[a] = 1.0/(@okno_k-a)
  		@md_vektor[a]=0
  		@okno_d.times do |s| #vypocet predoslych hodnot na zaklade velkosti okna d
  			#scita vykony predoslych dni o velkosti okno_d
  			@md_vektor[a] += @e_vektor[@posledny-@okno_k+a+1-(s+1)*@vzoriek_den].vykon
  		end #params[:okno_do].times...
  		#vypocita priemer md
  		@md_vektor[a] = @md_vektor[a] / @okno_d
  		#vypocita vektor V = d/Md / v pripade ze md je 0, priradi v hodnotu 1 = priemer
  		if @md_vektor[a] <= 0
  			@md_vektor[a] = 0
  			@v_vektor[a] = 1
  		else
  			@v_vektor[a] = (@e_vektor[@posledny-@okno_k+a+1].vykon / @md_vektor[a])
  		end
  	end # params[:okno_k]+1.times do....		
  	
  	# urci vahovaci faktor
  		pom =[]
  		@p_vektor.each_index do |hodnota|
  			pom[hodnota] = @v_vektor[hodnota]*@p_vektor[hodnota]
  		end
  	# urci vahovaci faktor GAPk
  	@gap_k = pom.inject(:+) / @p_vektor.inject(:+)	
  		
  	@pocet.times do |c_predikcie|
  		aktualny = @okno_k+c_predikcie
  		@md_vektor[aktualny] = 0
  		# urci priemer md pre predikovanu hodnotu
  		@okno_d.times do |d|
  			@md_vektor[aktualny] += @e_vektor[@posledny+1-(d+1)*@vzoriek_den].vykon 
  		end	# @okno_d.times...
  		@md_vektor[aktualny] = @md_vektor[aktualny] / @okno_d
  		
  	#samotny vypocet
  	
  	@e_vektor[@posledny+1] = RealValue.new(:cas=>@e_vektor[@posledny].cas+(24*60/@vzoriek_den).to_i.minutes)
  	
  	if [1,11,12].include? @e_vektor[@posledny].cas.month 
  		faktor_sezony=2
  	elsif[10,2].include? @e_vektor[@posledny].cas.month
  		faktor_sezony=1
  	elsif [6,7].include? @e_vektor[@posledny].cas.month
  		faktor_sezony=-1
  	else 
  		faktor_sezony = 0
  	end
  	if @e_vektor[@posledny+1].cas.hour <= 6+faktor_sezony || @e_vektor[@posledny+1].cas.hour >= 18-faktor_sezony
  		@alfa = 0.1
  	elsif @e_vektor[@posledny+1].cas.hour <= 9+faktor_sezony || @e_vektor[@posledny+1].cas.hour >= 15-faktor_sezony
  		@alfa = 0.3
  	else
  		@alfa = params[:alfa].to_f
  	end
  	
  	@e_vektor[@posledny+1].vykon = @alfa * @e_vektor[@posledny].vykon + @gap_k * (1-@alfa) * @md_vektor[aktualny]	
  	#dopocita vektor v pre buduci cyklus / ak je md vektor 0, tak priradi 1 - priemer
  #	if @md_vektor[aktualny] == 0
  #		@v_vektor[aktualny] = 1
  #	else
  #		@v_vektor[aktualny] = (@e_vektor[@posledny+1].vykon / @md_vektor[aktualny])
  #	end
  	# prenastavi index poslednej hodnoty vo vektore v
  	@posledny += 1  # = @e_vektor.index(@e_vektor.last)
  	end	# @pocet.times do...
  	
  	#priprava hodnot pre graficke zobrazenie
  	@predikcia = []
  	@realny_vykon = []
  	@okno_k.times do |okno|
  		@predikcia[okno] = @e_vektor[@posledny-@pocet-@okno_k+okno+1].vykon
  		@realny_vykon[okno] = @e_vektor[@posledny-@pocet-@okno_k+okno+1].vykon
  	end
	@pocet.times do |p|
		@predikcia[p+@okno_k] = @e_vektor[@posledny-@pocet+p+1].vykon || 0
		@realny_vykon[p+@okno_k] = RealValue.find(@start.id+p+1).vykon || 0
	end
	
	if @realny_vykon[@okno_k]>20
		@mape_1 = 100*(@realny_vykon[@okno_k]-@predikcia[@okno_k]).abs / @realny_vykon[@okno_k]
	else
		@mape_1 = nil
	end
	
	if @pocet >= 4
		r=4
		@mape_4 = 0
		4.times do |i|
			if @realny_vykon[@okno_k+i]>20
				@mape_4 += 100*(@realny_vykon[@okno_k+i]-@predikcia[@okno_k+i]).abs / @realny_vykon[@okno_k+i]
			else 
				r=0 
				break
			end
		end #4.times do
		if r != 0
			@mape_4 = @mape_4/r
		else
			@mape_4 = nil
		end
		if @pocet >= 16
			r=16
			@mape_16 = 0
			16.times do |i|
				if @realny_vykon[@okno_k+i]>20
					@mape_16 += 100*(@realny_vykon[@okno_k+i]-@predikcia[@okno_k+i]).abs / @realny_vykon[@okno_k+i]
				else
					r=0
					break
				end
			end
			if r != 0
				@mape_16 = @mape_16/r
			else
				@mape_16 = nil
			end
		end #if pocet>=16
		
	end # if pocet>=4

	@g = Gruff::Line.new
	@g.title = "Algoritmus WCMA-SF" 

	@g.data("Predikcia", @predikcia)
	@g.data("Reálne hodnoty", @realny_vykon)
	@g.data("Priemer Md", @md_vektor)


	@g.labels = {0 => @e_vektor[@posledny-@pocet-@okno_k].cas.strftime("%H:%M, %d.%m.")||"0", 
		((@pocet+@okno_k-1)/2).to_i => @e_vektor[@posledny-((@pocet+@okno_k-1)/2).to_i].cas.strftime("%H:%M, %d.%m.")||"0", 
				@pocet+@okno_k-1 => @e_vektor.last.cas.strftime("%H:%M, %d.%m.%y")||"0" }

	@g.write('public/assets/predikcia_WCMA.jpg')
	
#----------povodny algoritmus----------------------------------------------------------------------------
	
	#@start = RealValue.find(params[:datum])
  	#@okno_k = params[:okno_k].to_i
  	#@okno_d = params[:okno_d].to_i  	
  	@alfax = params[:alfa].to_f
  	#@pocet = params[:pocet].to_i
  	#@vzoriek_den = RealValue.where(:cas=>@start.cas.to_date..@start.cas.to_date+1.day).count-1
  	@md_vektorx = []
  	@v_vektorx = []
  	@p_vektorx = []
  	@start_s_oknom = RealValue.find(params[:datum].to_i-@okno_k+1) #je mozne menit casovy rozsah vzoriek
  	# do hlavneho vektora e nacita vsetky potrebne hodnoty pre vypocet
  	@e_vektorx = RealValue.where(
  				:cas=>(@start_s_oknom.cas-@okno_d.to_i.days)..@start.cas+1.minute)
  	# ulozi index poslednej hodnoty
  	@poslednyx = @e_vektorx.index(@e_vektorx.last)
  	#--vypocitame vektory Md,V, P pre prve okno
  	@okno_k.times do |a|  
  		@p_vektorx[a] = 1.0/(@okno_k-a)
  		@md_vektorx[a]=0
  		@okno_d.times do |s| #vypocet predoslych hodnot na zaklade velkosti okna d
  			#scita vykony predoslych dni o velkosti okno_d
  			@md_vektorx[a] += @e_vektorx[@poslednyx-@okno_k+a+1-(s+1)*@vzoriek_den].vykon
  		end #params[:okno_do].times...
  		#vypocita priemer md
  		@md_vektorx[a] = @md_vektorx[a] / @okno_d
  		#vypocita vektor V = d/Md / v pripade ze md je 0, priradi v hodnotu 1 = priemer
  		if @md_vektorx[a] <= 0
  			@md_vektorx[a] = 0
  			@v_vektorx[a] = 1
  		else
  			@v_vektorx[a] = (@e_vektorx[@poslednyx-@okno_k+a+1].vykon / @md_vektorx[a])
  		end
  	end # params[:okno_k]+1.times do....		
  		
  	# urci vahovaci faktor
  		pom =[]
  		@p_vektorx.each_index do |hodnota|
  			pom[hodnota] = @v_vektorx[hodnota]*@p_vektorx[hodnota]
  		end
  	# urci vahovaci faktor GAPk
  	@gap_kx = pom.inject(:+) / @p_vektorx.inject(:+)	
  		
  	@pocet.times do |c_predikcie|
  		aktualny = @okno_k+c_predikcie
  		@md_vektorx[aktualny] = 0
  		# urci priemer md pre predikovanu hodnotu
  		@okno_d.times do |d|
  			@md_vektorx[aktualny] += @e_vektorx[@poslednyx+1-(d+1)*@vzoriek_den].vykon 
  		end	# @okno_d.times...
  		@md_vektorx[aktualny] = @md_vektorx[aktualny] / @okno_d

  	#samotny vypocet  	
  	@e_vektorx[@poslednyx+1] = RealValue.new(:cas=>@e_vektorx[@poslednyx].cas+(24*60/@vzoriek_den).to_i.minutes)
  	@e_vektorx[@poslednyx+1].vykon = @alfax * @e_vektorx[@poslednyx].vykon + @gap_kx * (1-@alfax) * @md_vektorx[aktualny]	
  	#dopocita vektor v pre buduci cyklus / ak je md vektor 0, tak priradi 1 - priemer
  	if @md_vektorx[aktualny] == 0
  		@v_vektorx[aktualny] = 1
  	else
  		@v_vektorx[aktualny] = (@e_vektorx[@poslednyx+1].vykon / @md_vektorx[aktualny])
  	end
  	# prenastavi index poslednej hodnoty vo vektore v
  	@poslednyx += 1  # = @e_vektor.index(@e_vektor.last)
  	end	# @pocet.times do...
  	
  	#priprava hodnot pre graficke zobrazenie
  	@predikciax = []
  	@realny_vykonx = []
  	@okno_k.times do |okno|
  		@predikciax[okno] = @e_vektorx[@poslednyx-@pocet-@okno_k+okno+1].vykon
  		@realny_vykonx[okno] = @e_vektorx[@poslednyx-@pocet-@okno_k+okno+1].vykon
  	end
	@pocet.times do |p|
		@predikciax[p+@okno_k] = @e_vektorx[@poslednyx-@pocet+p+1].vykon || 0
		@realny_vykonx[p+@okno_k] = RealValue.find(@start.id+p+1).vykon || 0
	end
	
	if @realny_vykonx[@okno_k]>20
		@mape_1x = 100*(@realny_vykonx[@okno_k]-@predikciax[@okno_k]).abs / @realny_vykonx[@okno_k]
	else
		@mape_1x = nil
	end
	
	if @pocet >= 4
		r=4
		@mape_4x = 0
		4.times do |i|
			if @realny_vykonx[@okno_k+i]>20
				@mape_4x += 100*(@realny_vykonx[@okno_k+i]-@predikciax[@okno_k+i]).abs / @realny_vykonx[@okno_k+i]
			else 
				r=0 
				break
			end
		end #4.times do
		if r != 0
			@mape_4x = @mape_4x/r
		else
			@mape_4x = nil
		end
		if @pocet >= 16
			r=16
			@mape_16x = 0
			16.times do |i|
				if @realny_vykonx[@okno_k+i]>20
					@mape_16x += 100*(@realny_vykonx[@okno_k+i]-@predikciax[@okno_k+i]).abs / @realny_vykonx[@okno_k+i]
				else
					r=0
					break
				end
			end
			if r != 0
				@mape_16x = @mape_16x/r
			else
				@mape_16x = nil
			end
		end #if pocet>=16
		
	end # if pocet>=4

	@g = Gruff::Line.new
	@g.title = "Algoritmus WCMA" 

	@g.data("Predikcia", @predikciax)
	@g.data("Reálne hodnoty", @realny_vykonx)
	@g.data("Priemer Md", @md_vektorx)


	@g.labels = {0 => @e_vektorx[@poslednyx-@pocet-@okno_k].cas.strftime("%H:%M, %d.%m.")||"0", 
				((@pocet+@okno_k-1)/2).to_i => @e_vektorx[@posledny-((@pocet+@okno_k-1)/2).to_i].cas.strftime("%H:%M, %d.%m.")||"0", 
				@pocet+@okno_k-1 => @e_vektorx.last.cas.strftime("%H:%M, %d.%m.%y")||"0" }

	@g.write('public/assets/predikcia_WCMAx.jpg')
	
  	
  	end #end if params[:datum]
  	
  end





end
