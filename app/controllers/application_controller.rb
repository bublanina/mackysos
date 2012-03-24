# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  
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
		if pole.size >= 7 
		#-- vytvori novy  prazdny objekt RealValue
		hodnota = RealValue.new
		hodnota.cas = DateTime.new(pole[2].to_i,pole[1].to_i,pole[0].to_i,pole[3].to_i,pole[4].to_i,0)
		hodnota.vykon = pole[6]
		hodnota.save
		end # if pole.size
	end # each do |riadok|
	redirect_to :root
	
  	end # def importuj
  
end
