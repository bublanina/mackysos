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
#-----------------------------------------------------------------------------------  		
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
#------------------------------------------------------------------------------------  	
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
  	
  end # end def index
  
  
  
  def neuronova_siet
  
  	if params[:datum]		
  		@start = RealValue.find(params[:datum])
  		@trenovanie1 = RealValue.where(:cas=>@start.cas-20.days..@start.cas)#.
#  								where("vykon >= 0")
  		# normalizacia
  		@trenovanie_osvit = []
  		@trenovanie_teplota = []
  		@trenovanie_out = []
  		@trenovanie1.each_with_index do |sada|
  		# ako 0 je urceny minimalny vykon
  			@trenovanie_out << (sada.vykon-0)/
  						(RealValue.maximum("vykon")-0)#RealValue.minimum("vykon"))
  			@trenovanie_osvit << (sada.osvit-RealValue.minimum("osvit"))/
  						(RealValue.maximum("osvit")-RealValue.minimum("osvit"))
  			@trenovanie_teplota << (sada.teplota-RealValue.minimum("teplota"))/
  							(RealValue.maximum("teplota")-RealValue.minimum("teplota"))
  		end #trenovanie.each do...
  		@pocet_neuronov = params[:pocet_neuronov].to_i || 3

  		#vytvori maticu vstupov
  		@trenovanie = Matrix[@trenovanie_osvit, @trenovanie_teplota].t
  		@trenovanie_out = Matrix[@trenovanie_out].t
		
  		#inicializuje nahodne vahy
  		vahy1=[]
  		vahy2=[]
  		vahyout=[]
  		@pocet_neuronov.times do
  			vahy1 << rand-0.5
  			vahy2 << rand-0.5
  			vahyout << rand-0.5	
  		end
  		@vahy_v = Matrix[vahy1,vahy2]
  		@vahy_w = Matrix.column_vector(vahyout)
  		i=0
  		@mi=0.6
  		@alfa=0.1
  		@delta_w0 = Matrix.build(@vahy_w.row_size,@vahy_w.column_size) { 0 }
  		@delta_v0 = Matrix.build(@vahy_v.row_size,@vahy_v.column_size) { 0 }
  		
  		# vytvori novy stlpcovy vektor z riadku matice
  		@error = 1
  		@error_learning = []
  		time = Time.now
  		cyklov = 0
  		@global_error = 0
  		# cyklus ucenia sa opakuje kym neprebehne 200 cyklov alebo chyba nie je dostatocne nizka
  		until (cyklov>=300)
  			@vstup = Matrix.column_vector(@trenovanie.row(i))
  			@vystup = Matrix.column_vector(@trenovanie_out.row(i))
  		 		
  			#vypocita vstupy do skrytych neuronov - 
  			# transpose = transponovana matica
  			# krok 5
  			@vstup_hidden = @vahy_v.transpose*@vstup
  			# krok 6
  			@vystup_hidden = Matrix.build(@vstup_hidden.row_size,1) { 0 }
  			pole=[]
  			@vstup_hidden.column(0).each_with_index do |riadok, row, col|
  				pole[row] = 1/(1+Math.exp(-1*riadok))
  			end
  			@vystup_hidden=Matrix.column_vector(pole)
  			# krok 7
  			@vstup_final = @vahy_w.transpose*@vystup_hidden
  			pole = []
  			@vstup_final.column(0).each_with_index do |riadok, row, col|
  				pole[row] = 1/(1+Math.exp(-1*riadok))
  			end
  			# 
  			@vystup_final = Matrix[pole]
  			# 7
  			@error = (@vystup-@vystup_final).sum**2
  			#if @error < 0.00000001
  			 
  			 #else 
  			 #cyklov = 0
  			 #end
  			# 8
  			@d = ((@vystup-@vystup_final)*@vystup_final*(1-@vystup_final.sum)).sum
  			@y = @vystup_hidden*@d
  			# 9

  			@delta_w1 = @alfa*@delta_w0 + @mi*@y
  			# 10
  			@e = @vahy_w*@d
  			# 11
  			@d2=[]
  			@vystup_hidden.row_size.times do |i|
  				@d2[i] = @e.element(i,0)*@vystup_hidden.element(i,0)*(1-@vystup_hidden.element(i,0))
  			end
  			@d2 = Matrix.column_vector(@d2)
			# 12
			@x = @vstup*@d2.t
			# 13

  			@delta_v1 = @alfa*@delta_v0 + @mi*@x
  			# 14
  			@vahy_v = @vahy_v + @delta_v1
  			@vahy_w = @vahy_w + @delta_w1
  			@delta_w0 = @delta_w1
  			@delta_v0 = @delta_v1
  			
  			
  			i=(i+1).modulo(@trenovanie.row_size)
  			if i==0
  			
  				@trenovanie.row_size.times do |r|
  					@vstup = Matrix.column_vector(@trenovanie.row(r))
  					@vystup = Matrix.column_vector(@trenovanie_out.row(r))
  		 			
  					#vypocita vstupy do skrytych neuronov - 
  					# transpose = transponovana matica
  					# krok 5
  					@vstup_hidden = @vahy_v.transpose*@vstup
  					# krok 6
  					@vystup_hidden = Matrix.build(@vstup_hidden.row_size,1) { 0 }
  					pole=[]
  					@vstup_hidden.column(0).each_with_index do |riadok, row, col|
  						pole[row] = 1/(1+Math.exp(-1*riadok))
  					end  # @vstup_hidden....
  					@vystup_hidden=Matrix.column_vector(pole)
  					# krok 7
  					@vstup_final = @vahy_w.transpose*@vystup_hidden
  					pole = []
  					@vstup_final.column(0).each_with_index do |riadok, row, col|
  						pole[row] = 1/(1+Math.exp(-1*riadok))
  					end #@vstup_final.column(0)
  					# 
  					@vystup_final = Matrix[pole]
  					# 7
  					@error = (@vystup-@vystup_final).sum**2
  					@global_error += @error
  				end # @trenovanie.each....
  				
  				@global_error = @global_error/(@trenovanie.row_size)
  				@error_learning << @global_error
  				cyklov = cyklov +1
  			end
  			# trenovanie konci ak je siet dostatocne naucena
  			if (i==0)&&(@global_error<=0.001)
  				break
  			end # if i==0 && ...
  			
  		end #while error
  		
  		@dlzka = Time.now - time
  		
  	@g_neuro = Gruff::Line.new(800)
	@g_neuro.title = "Neurónová sieť back-propagation - trénovanie" 
	@g_neuro.data("Chyba", @error_learning)
	@g_neuro.write('public/assets/neuro_learning.jpg')
	
  	@predikcia = []
  	@real = []
  	RealValue.where(:cas=>@start.cas..(@start.cas+3.days)).each do |hodnota|
  		@predikcia << predikuj(hodnota, @vahy_v, @vahy_w)
  		if hodnota.vykon >=0
  			@real << hodnota.vykon
  		else
  			@real << 0
  		end
  	end #each.do |hodnota|  	
  		
  	@g_predik = Gruff::Line.new(800)
	@g_predik.title = "Neurónová sieť back-propagation - predikcia" 
	@g_predik.data("Predikcia", @predikcia)
	@g_predik.data("Reálne hodnoty", @real)
	@g_predik.write('public/assets/neuro_prediction.jpg')	
  		
  	end # if params[:datum]
  	
  end # def neuronova siet
#------------------------------------------------------------------------------

   def neuronova_siet2
  
  	if params[:datum]		
  		@start = RealValue.find(params[:datum])
  		@trenovanie1 = RealValue.where(:cas=>@start.cas-20.days..@start.cas)#.
#  								where("vykon >= 0")
  		# normalizacia
  		@trenovanie_osvit = []
  		@trenovanie_teplota = []
  		@trenovanie_cas = []
  		@trenovanie_out = []
  		@trenovanie1.each_with_index do |sada|
  		# ako 0 je urceny minimalny vykon
  			@trenovanie_out << (sada.vykon-0)/
  						(RealValue.maximum("vykon")-0)#RealValue.minimum("vykon"))
  			@trenovanie_osvit << (sada.osvit-RealValue.minimum("osvit"))/
  						(RealValue.maximum("osvit")-RealValue.minimum("osvit"))
  			@trenovanie_teplota << (sada.teplota-RealValue.minimum("teplota"))/
  							(RealValue.maximum("teplota")-RealValue.minimum("teplota"))
  			@trenovanie_cas <<  sada.cas.hour/24.0 + sada.cas.min/60
  		end #trenovanie.each do...
  		@pocet_neuronov = params[:pocet_neuronov].to_i || 3

  		#vytvori maticu vstupov
  		@trenovanie = Matrix[@trenovanie_osvit, @trenovanie_teplota, @trenovanie_cas].t
  		@trenovanie_out = Matrix[@trenovanie_out].t
		
  		#inicializuje nahodne vahy
  		vahy1=[]
  		vahy2=[]
  		vahy3=[]
  		vahyout=[]
  		@pocet_neuronov.times do
  			vahy1 << rand-0.5
  			vahy2 << rand-0.5
  			vahy3 << rand-0.5
  			vahyout << rand-0.5	
  		end
  		@vahy_v = Matrix[vahy1,vahy2, vahy3]
  		@vahy_w = Matrix.column_vector(vahyout)
  		i=0
  		@mi=0.6
  		@alfa=0.1
  		@delta_w0 = Matrix.build(@vahy_w.row_size,@vahy_w.column_size) { 0 }
  		@delta_v0 = Matrix.build(@vahy_v.row_size,@vahy_v.column_size) { 0 }
  		
  		# vytvori novy stlpcovy vektor z riadku matice
  		@error = 1
  		@error_learning = []
  		time = Time.now
  		cyklov = 0
  		@global_error = 0
  		# cyklus ucenia sa opakuje kym neprebehne 200 cyklov alebo chyba nie je dostatocne nizka
  		until (cyklov>=300)
  			@vstup = Matrix.column_vector(@trenovanie.row(i))
  			@vystup = Matrix.column_vector(@trenovanie_out.row(i))
  		 		
  			#vypocita vstupy do skrytych neuronov - 
  			# transpose = transponovana matica
  			# krok 5
  			@vstup_hidden = @vahy_v.transpose*@vstup
  			# krok 6
  			@vystup_hidden = Matrix.build(@vstup_hidden.row_size,1) { 0 }
  			pole=[]
  			@vstup_hidden.column(0).each_with_index do |riadok, row, col|
  				pole[row] = 1/(1+Math.exp(-1*riadok))
  			end
  			@vystup_hidden=Matrix.column_vector(pole)
  			# krok 7
  			@vstup_final = @vahy_w.transpose*@vystup_hidden
  			pole = []
  			@vstup_final.column(0).each_with_index do |riadok, row, col|
  				pole[row] = 1/(1+Math.exp(-1*riadok))
  			end
  			# 
  			@vystup_final = Matrix[pole]
  			# 7
  			@error = (@vystup-@vystup_final).sum**2
  			#if @error < 0.00000001
  			 
  			 #else 
  			 #cyklov = 0
  			 #end
  			# 8
  			@d = ((@vystup-@vystup_final)*@vystup_final*(1-@vystup_final.sum)).sum
  			@y = @vystup_hidden*@d
  			# 9

  			@delta_w1 = @alfa*@delta_w0 + @mi*@y
  			# 10
  			@e = @vahy_w*@d
  			# 11
  			@d2=[]
  			@vystup_hidden.row_size.times do |i|
  				@d2[i] = @e.element(i,0)*@vystup_hidden.element(i,0)*(1-@vystup_hidden.element(i,0))
  			end
  			@d2 = Matrix.column_vector(@d2)
			# 12
			@x = @vstup*@d2.t
			# 13

  			@delta_v1 = @alfa*@delta_v0 + @mi*@x
  			# 14
  			@vahy_v = @vahy_v + @delta_v1
  			@vahy_w = @vahy_w + @delta_w1
  			@delta_w0 = @delta_w1
  			@delta_v0 = @delta_v1
  			
  			
  			i=(i+1).modulo(@trenovanie.row_size)
  			if i==0
  			
  				@trenovanie.row_size.times do |r|
  					@vstup = Matrix.column_vector(@trenovanie.row(r))
  					@vystup = Matrix.column_vector(@trenovanie_out.row(r))
  		 			
  					#vypocita vstupy do skrytych neuronov - 
  					# transpose = transponovana matica
  					# krok 5
  					@vstup_hidden = @vahy_v.transpose*@vstup
  					# krok 6
  					@vystup_hidden = Matrix.build(@vstup_hidden.row_size,1) { 0 }
  					pole=[]
  					@vstup_hidden.column(0).each_with_index do |riadok, row, col|
  						pole[row] = 1/(1+Math.exp(-1*riadok))
  					end  # @vstup_hidden....
  					@vystup_hidden=Matrix.column_vector(pole)
  					# krok 7
  					@vstup_final = @vahy_w.transpose*@vystup_hidden
  					pole = []
  					@vstup_final.column(0).each_with_index do |riadok, row, col|
  						pole[row] = 1/(1+Math.exp(-1*riadok))
  					end #@vstup_final.column(0)
  					# 
  					@vystup_final = Matrix[pole]
  					# 7
  					@error = (@vystup-@vystup_final).sum**2
  					@global_error += @error
  				end # @trenovanie.each....
  				
  				@global_error = @global_error/(@trenovanie.row_size)
  				@error_learning << @global_error
  				cyklov = cyklov +1
  			end
  			# trenovanie konci ak je siet dostatocne naucena
  			if (i==0)&&(@global_error<=0.001)
  				break
  			end # if i==0 && ...
  			
  		end #while error
  		
  		@dlzka = Time.now - time
  		
  	@g_neuro = Gruff::Line.new(800)
	@g_neuro.title = "Neurónová sieť back-propagation - trénovanie" 
	@g_neuro.data("Chyba", @error_learning)
	@g_neuro.write('public/assets/neuro_learning.jpg')
	
  	@predikcia = []
  	@real = []
  	RealValue.where(:cas=>@start.cas..(@start.cas+3.days)).each do |hodnota|
  		@predikcia << predikuj2(hodnota, @vahy_v, @vahy_w)
  		if hodnota.vykon >=0
  			@real << hodnota.vykon
  		else
  			@real << 0
  		end
  	end #each.do |hodnota|  	
  		
  	@g_predik = Gruff::Line.new(800)
	@g_predik.title = "Neurónová sieť back-propagation - predikcia" 
	@g_predik.data("Predikcia", @predikcia)
	@g_predik.data("Reálne hodnoty", @real)
	@g_predik.write('public/assets/neuro_prediction.jpg')	
  		
  	end # if params[:datum]
  	
  end # def neuronova siet2
  
  
#------------------------------------------------------------------------------


  def predikuj(hodnota, vahy_v, vahy_w)
    osvit = (hodnota.osvit-RealValue.minimum("osvit"))/
  						(RealValue.maximum("osvit")-RealValue.minimum("osvit"))
  	teplota = (hodnota.teplota-RealValue.minimum("teplota"))/
  							(RealValue.maximum("teplota")-RealValue.minimum("teplota"))
  	trenovanie = Matrix[[osvit], [teplota]].t
  	vstup = Matrix.column_vector(trenovanie.row(0))
  	#vypocita vstupy do skrytych neuronov - 
  	# transpose = transponovana matica
  	# krok 5
  	vstup_hidden = vahy_v.transpose*vstup
  	# krok 6
  	vystup_hidden = Matrix.build(vstup_hidden.row_size,1) { 0 }
  	pole=[]
  	vstup_hidden.column(0).each_with_index do |riadok, row, col|
  		pole[row] = 1/(1+Math.exp(-1*riadok))
  	end
  	vystup_hidden=Matrix.column_vector(pole)
  	# krok 7
  	vstup_final = vahy_w.transpose*vystup_hidden
  	pole = []
  	vstup_final.column(0).each_with_index do |riadok, row, col|
  		pole[row] = 1/(1+Math.exp(-1*riadok))
  	end
  	# 0 je nastaveny minimalny vykon
  	vysledok = Matrix[pole].sum*(RealValue.maximum("vykon")-0)+0
  	
  	return vysledok
  end
  
  def predikuj2(hodnota, vahy_v, vahy_w)
    osvit = (hodnota.osvit-RealValue.minimum("osvit"))/
  						(RealValue.maximum("osvit")-RealValue.minimum("osvit"))
  	teplota = (hodnota.teplota-RealValue.minimum("teplota"))/
  							(RealValue.maximum("teplota")-RealValue.minimum("teplota"))
  	cas = hodnota.cas.hour/24 + hodnota.cas.min/60
  	trenovanie = Matrix[[osvit], [teplota], [cas]].t
  	vstup = Matrix.column_vector(trenovanie.row(0))
  	#vypocita vstupy do skrytych neuronov - 
  	# transpose = transponovana matica
  	# krok 5
  	vstup_hidden = vahy_v.transpose*vstup
  	# krok 6
  	vystup_hidden = Matrix.build(vstup_hidden.row_size,1) { 0 }
  	pole=[]
  	vstup_hidden.column(0).each_with_index do |riadok, row, col|
  		pole[row] = 1/(1+Math.exp(-1*riadok))
  	end
  	vystup_hidden=Matrix.column_vector(pole)
  	# krok 7
  	vstup_final = vahy_w.transpose*vystup_hidden
  	pole = []
  	vstup_final.column(0).each_with_index do |riadok, row, col|
  		pole[row] = 1/(1+Math.exp(-1*riadok))
  	end
  	# 0 je nastaveny minimalny vykon
  	vysledok = Matrix[pole].sum*(RealValue.maximum("vykon")-0)+0
  	
  	return vysledok
  end


end
