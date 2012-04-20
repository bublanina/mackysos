# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  
    require 'matrix'
  
  
  def predikuj_WCMA
  	
  	@start = RealValue.find(params[:datum])
  	@e_vektor = RealValue.where(
  				:cas=>(@start.cas-params[:okno_d].to_i.days)..@start.cas, 
  				:select=>"vykon")

  redirect_to :root		
  
  end # def predikuj
  
    def importuj
  #--nacitavanie suboru s testovacimi vzorkami do premennej rub
  	rub = IO.readlines('public/Pcelk2.txt')
  	#-- prechadzanie suboru po riadkoch
	rub.each do |riadok|
		#--rozdelenie riadku podla oddelovaca bodkociarka
		pole = riadok.split(";")
		if pole.size >= 6 
		#-- vytvori novy  prazdny objekt RealValue
		hodnota = RealValue.new
		hodnota.cas = DateTime.new(pole[2].to_i,pole[1].to_i,pole[0].to_i,pole[3].to_i,pole[4].to_i,0)
		if pole[6]
			hodnota.vykon = pole[6]
		else
			hodnota.vykon = 0
		end
		hodnota.save
		end # if pole.size
	end # each do |riadok|
	redirect_to :root
	
  	end # def importuj
  	
  	def importuj_osvit
  		rub = IO.readlines('public/Osvit2.txt')
  		rub.each do |riadok|
		#--rozdelenie riadku podla oddelovaca bodkociarka
		pole = riadok.split(";")
		if pole.size >= 7 
		@cas = DateTime.new(pole[2].to_i,pole[1].to_i,pole[0].to_i,pole[3].to_i,pole[4].to_i,0)
		if RealValue.where(:cas=>@cas).exists?
			hodnota = RealValue.where(:cas=>@cas).first
			hodnota.osvit = pole[6]
			hodnota.save
		end
		end # if pole.size
	end # each do |riadok|
	
	# pokusi sa zaplnit prazdne hodnoty / chyby, nenamerane a pod.
		RealValue.where(:osvit=>nil).each do |rv|
			rv.osvit = (RealValue.find(rv.id-1).osvit+RealValue.where("id > ? and osvit >= ?", rv.id,0).first.osvit)/2
			rv.save
		end
		
	redirect_to :root
  	end # def importuj osvit
  	
  	def importuj_teplotu
  		rub = IO.readlines('public/Teplota2.txt')
  		rub.each do |riadok|
		#--rozdelenie riadku podla oddelovaca bodkociarka
		pole = riadok.split(";")
		if pole.size >= 7 
			@cas = DateTime.new(pole[2].to_i,pole[1].to_i,pole[0].to_i,pole[3].to_i,pole[4].to_i,0)
			if RealValue.where(:cas=>@cas).exists?
				hodnota = RealValue.where(:cas=>@cas).first
				hodnota.teplota = pole[6]
				hodnota.save
			end
		end # if pole.size
		end # each do |riadok|
		
			# pokusi sa zaplnit prazdne hodnoty / chyby, nenamerane a pod.
		RealValue.where(:teplota=>nil).each do |rv|
			rv.teplota = (RealValue.find(rv.id-1).teplota+RealValue.where("id > ? and teplota >= ?", rv.id,0).first.teplota)/2
			rv.save
		end
		
		redirect_to :root
  	end # def importuj teplotu
  	
  
end
