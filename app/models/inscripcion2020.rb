class Inscripcion2020 < ApplicationRecord
  belongs_to :proximo_grado

  def self.FindInscripcion(a)
    return Inscripcion2020.where("alumno_id=#{a} AND reinscripcion AND #{ConsultaFecha()}").order(anio: :desc).first rescue nil
  end

  def PuedeInscribir()
    return (inhabilitado != nil) && !inhabilitado && (fecha_pase == nil)
  end

  def EstaInscripto()
    return fecha_inscripto != nil
  end

  def HayVale()
    return fecha_vale != nil
  end

  def EstaRegistrado()
    return fecha_registrado != nil
  end

  def self.ConsultaFecha()
    return "fecha_comienzo<='#{DateTime.now.strftime("%Y-%m-%d")}' AND (fecha_fin IS NULL OR fecha_fin>='#{DateTime.now.strftime("%Y-%m-%d")}')"
  end

  def self.Consulta(alumno, campo, tabla)
    return "fecha_comienzo<='#{DateTime.now.strftime("%Y-%m-%d")}' AND (fecha_fin IS NULL OR fecha_fin>='#{DateTime.now.strftime("%Y-%m-%d")}') AND " +
           "(general OR (id IN (SELECT #{campo} FROM #{tabla} WHERE alumno_id=#{alumno})))"
  end



  def self.OpcionesGrados(inscripcionAlumno)
    opciones = Array.new
    ProximoGrado.where("grado_id=#{inscripcionAlumno.grado_id} AND anio=2021").order(:nombre).each do |opcion|
      opciones.push( ["#{opcion.nombre} - $#{opcion.precio.to_i.to_s}",opcion.id] )
    end 
    return opciones
  end


  def self.OpcionesConvenio(inscripcionAlumno)
    opciones = Array.new
    opciones.push( ["",nil] )
    Convenio2020.where(ConsultaFecha()).order(:nombre).each do |opcion|
      opciones.push( [opcion.nombre,opcion.id] )
    end 
    return opciones
  end

  def self.OpcionesAfinidad(inscripcionAlumno)
    afinidad = Afinidad2020.where("id IN (SELECT afinidad2020_id FROM inscripcion2020s WHERE alumno_id=#{inscripcionAlumno.alumno_id} AND #{ConsultaFecha()})").first
    return afinidad
  end

  def self.OpcionesAdicional(inscripcionAlumno)
    inscripcion = Inscripcion2020.where("alumno_id=#{inscripcionAlumno.alumno_id} AND #{ConsultaFecha()}").first
    return inscripcion
  end

  def self.OpcionesHermanos(inscripcionAlumno)
    opciones = Array.new
    opciones.push( ["",nil] )
    Hermanos2020.where(ConsultaFecha()).order(:nombre).each do |opcion|
      opciones.push( [opcion.nombre,opcion.id] )
    end 
    return opciones
  end

  def self.OpcionesCuotas(inscripcionAlumno)
    opciones = Array.new
    
    Cuota2020.where(Consulta(inscripcionAlumno.alumno_id,"cuota2020_id","cuota2020_alumnos")).order(:nombre).each do |opcion|
      opciones.push( [opcion.nombre,opcion.id] )
    end 
    return opciones
  end

  def self.OpcionesMatricula(inscripcionAlumno)
    opciones = Array.new
    
    Matricula2020.where(Consulta(inscripcionAlumno.alumno_id,"matricula2020_id","matricula2020_alumnos")).order(:nombre).each do |opcion|
      opciones.push( [opcion.nombre,opcion.id] )
    end 
    return opciones
  end

  # def CalcularMovimientos()

  #   movimientos = Array.new

  #   proximo_grado = ProximoGrado.find(proximo_grado_id) rescue nil
  #   if proximo_grado == nil || cuota2020_id == nil
  #     return movimientos
  #   end

  #   importe_total = proximo_grado.precio

  #   descuentos = Array.new
  #   if fija != nil
  #       descuentos.push(["FIJO",false,fija])
  #   else
  #     c = Convenio2020.find(convenio2020_id) rescue nil
  #     if c != nil
  #       descuentos.push([c.toString(),true,c.descuento])
  #     end
  #   end

  #   c = Afinidad2020.find(afinidad2020_id) rescue nil
  #   if c != nil
  #     descuentos.push([c.toString(),true,c.descuento])
  #   end
  #   if adicional != nil
  #     descuentos.push(["Adicional #{Common.decimal_to_string(adicional,2)}%",true,adicional])
  #   end
  #   if congelado != nil
  #     descuentos.push(["Congelado #{Common.decimal_to_string(congelado,2)}%",true,congelado])
  #   end
  #   c = Hermanos2020.find(hermanos2020_id) rescue nil
  #   if c != nil
  #     descuentos.push([c.toString(),true,c.descuento])
  #   end

  #   cuotas = Array.new
  #   LineaCuota2020.where("cuota2020_id=#{cuota2020_id}").order(:fecha).each do |cuota|
  #     cuotas.push([cuota.cantidad,cuota.fecha,cuota.numerador,cuota.denominador])
  #   end

  #   total_cuotas = 0
  #   cuotas.each do |cuota|
  #     total_cuotas = total_cuotas + cuota[0]
  #   end

  #   devolucion = 0

  #   num_cuota = 1
  #   cuotas.each do |cuota|      
  #     (1..cuota[0]).each do |x|
  #       importe = importe_total*cuota[2]/cuota[3]

  #       fecha = cuota[1] + (x-1).month

  #       mov = [fecha,"CUOTA #{anio} #{num_cuota}/#{total_cuotas}",(importe+0.5).to_i,proximo_grado.rubro_id]

  #       if (fecha_comienzo == nil || fecha >= fecha_comienzo) && (fecha_ultima == nil || fecha < fecha_ultima)
  #         if fecha_fin != nil && fecha >= fecha_fin
  #           devolucion = devolucion + mov[2]
  #         end
  #         if fecha_primera != nil && fecha < fecha_primera
  #           mov[0] = fecha_primera
  #         end
  #         movimientos.push(mov)
  #       end

  #       descuentos.each do |descuento| 
  #         if descuento[1]
  #           desc = importe*descuento[2]/100
  #           importe = importe - desc

  #           mov = [fecha,"DESCUENTO #{descuento[0]} #{anio} #{num_cuota}/#{total_cuotas}",(-desc+0.5).to_i,proximo_grado.rubro_id]

  #           if (fecha_comienzo == nil || fecha >= fecha_comienzo) && (fecha_ultima == nil || fecha < fecha_ultima)
  #             if fecha_fin != nil && fecha >= fecha_fin
  #               devolucion = devolucion + mov[2]
  #             end
  #             if fecha_primera != nil && fecha < fecha_primera
  #               mov[0] = fecha_primera
  #             end
  #             movimientos.push(mov)
  #           end

  #         else
  #           desc = importe-descuento[2]*cuota[2]/cuota[3]
  #           importe = importe - desc

  #           mov = [fecha,"DESCUENTO #{descuento[0]} #{anio} #{num_cuota}/#{total_cuotas}",(-desc+0.5).to_i,proximo_grado.rubro_id]

  #           if (fecha_comienzo == nil || fecha >= fecha_comienzo) && (fecha_ultima == nil || fecha < fecha_ultima)
  #             if fecha_fin != nil && fecha >= fecha_fin
  #               devolucion = devolucion + mov[2]
  #             end
  #             if fecha_primera != nil && fecha < fecha_primera
  #               mov[0] = fecha_primera
  #             end
  #             movimientos.push(mov)
  #           end

  #         end          
  #       end
  #       num_cuota = num_cuota+1
  #     end
  #   end

  #   if devolucion > 0 
  #     mov = [fecha_ultima,"DEVOLUCIÓN CUOTAS",-devolucion,proximo_grado.rubro_id]
  #     movimientos.push(mov)
  #   end

  #   matricula = Matricula2020.find(matricula2020_id) rescue nil
  #   matricula2020ProximoGrado = Matricula2020ProximoGrado.where("matricula2020_id=#{matricula2020_id} AND proximo_grado_id=#{proximo_grado_id}").first rescue nil
  #   if matricula != nil && matricula2020ProximoGrado != nil
      
  #     importe_total = matricula2020ProximoGrado.precio

  #     cuotas = Array.new
  #     lineas = LineaMatricula2020.where("matricula2020_id=#{matricula2020_id}").order(:fecha) 
  #     lineas.each do |cuota|
  #       cuotas.push([cuota.cantidad,cuota.fecha,cuota.numerador,cuota.denominador])
  #     end

  #     total_cuotas = 0
  #     cuotas.each do |cuota|
  #       total_cuotas = total_cuotas + cuota[0]
  #     end

  #     num_cuota = 1
  #     cuotas.each do |cuota|     
  #       (1..cuota[0]).each do |x|
          
  #         fecha = cuota[1] + (x-1).month
  #         importe = importe_total*cuota[2]/cuota[3]

  #         mov = [fecha,"Matrícula #{anio} #{num_cuota}/#{total_cuotas}",(importe+0.5).to_i,proximo_grado.matricula_rubro]
  #         movimientos.push(mov)

  #         num_cuota = num_cuota+1
  #       end
  #     end
  #   end

  #   return movimientos

  # end

  # def CalcularMovimientosToStr()

  #   movimientos = CalcularMovimientos()

  #   i = 0
  #   str = ""
  #   movimientos.each do |mov|

  #     if fecha_vale != nil
  #       m = Movimiento.where(inscripcion2020_id: id, inscripcion2020_indice: i).first
  #       m ||= Movimiento.new
  #       m.inscripcion2020_id = id
  #       m.inscripcion2020_indice = i    
  #       m.cuenta_id = cuenta_id
  #       m.alumno = alumno_id
  #       m.fecha = mov[0]
  #       m.descripcion = mov[1].upcase
  #       m.debe = (mov[2]+0.5).to_i
  #       m.ejercicio = anio
  #       m.rubro_id = mov[3]
  #       m.haber = 0
  #       m.save!
  #     end
  #     str = str + "#{I18n.l(mov[0], format: "%d-%m-%Y")} = #{mov[1].upcase} = #{mov[2]} ====="

  #     i = i+1
  #   end

  #   if fecha_vale != nil
  #     Movimiento.where("inscripcion2020_id=#{id} AND inscripcion2020_indice>=#{i}").delete_all
  #   end
    
  #   return str

  # end


  def CalcularPrecio()

    movimientos = Array.new

    proximo_grado = ProximoGrado.find(proximo_grado_id) rescue nil
    if proximo_grado == nil || cuota2020_id == nil
      return movimientos
    end

    importe_total = proximo_grado.precio

    descuentos = Array.new
    if fija != nil
        descuentos.push(["FIJO",false,fija])
    else
      c = Convenio2020.find(convenio2020_id) rescue nil
      if c != nil
        descuentos.push([c.toString(),true,c.descuento])
      end
    end

    c = Afinidad2020.find(afinidad2020_id) rescue nil
    if c != nil
      descuentos.push([c.toString(),true,c.descuento])
    end
    if adicional != nil
      descuentos.push(["Adicional #{Common.decimal_to_string(adicional,2)}%",true,adicional])
    end
    if congelado != nil
      descuentos.push(["Congelado #{Common.decimal_to_string(congelado,2)}%",true,congelado])
    end
    c = Hermanos2020.find(hermanos2020_id) rescue nil
    if c != nil
      descuentos.push([c.toString(),true,c.descuento])
    end

    cuotas = Array.new
    LineaCuota2020.where("cuota2020_id=#{cuota2020_id}").order(:fecha).each do |cuota|
      cuotas.push([cuota.cantidad,cuota.fecha,cuota.numerador,cuota.denominador])
    end

    total_cuotas = 0
    cuotas.each do |cuota|
      total_cuotas = total_cuotas + cuota[0]
    end

    devolucion = 0

    num_cuota = 1
    cuotas.each do |cuota|      
      importe = importe_total*cuota[2]/cuota[3]
      fecha = cuota[1] 
      mov = [cuota[0],(importe+0.5).to_i,fecha + 9.days]
      descuentos.each do |descuento| 
        if descuento[1]
          desc = importe*descuento[2]/100
          importe = importe - desc
          mov[1] = mov[1]+(-desc+0.5).to_i
        else
          desc = importe-descuento[2]*cuota[2]/cuota[3]
          importe = importe - desc
          mov[1] = mov[1]+(-desc+0.5).to_i
        end          
      end
      movimientos.push(mov)
    end

    return movimientos

  end

  def CalcularPrecioToStr()

    str = ""

    cuotas = CalcularPrecio()

    total = 0
    cuotas.each do |cuota|
      if str != ""
        str = str + " + "        
      end
      if cuota[2] != nil
        str = str + "(#{cuota[2].strftime("%d/%m/%Y")})"
      end
      str = str + " #{cuota[0]} x #{cuota[1]}"

      total = total + cuota[0]*cuota[1]
    end
    str = str + " = #{total}"

    return str
  end



  def self.numero_a_letras(n, uno)
    s = ""
    if (n/1000>0)
      s = numero_a_letras((n/1000).to_i,false) + " mil ";
    end
    n = (n%1000).to_i;
    case (n/100).to_i
    when 1
      if n%100 != 0
        s = s + "ciento"
      else
        s = s + "cien"
      end
    when 2
      s = s + "doscientos"
    when 3
      s = s + "trescientos"
    when 4
      s = s + "cuatrocientos"
    when 5
      s = s + "quinientos"
    when 6
      s = s + "siescientos"
    when 7
      s = s + "setecientos"
    when 8
      s = s + "ochocientos"
    when 9
      s = s + "novecientos"
    end
    n = (n%100).to_i
    if n > 0
      s = s + " "
    end
    case (n/10).to_i
    when 3
      s = s + "treinta"
    when 4
      s = s + "cuarenta"
    when 5
      s = s + "cincuenta"
    when 6
      s = s + "sesenta"
    when 7
      s = s + "setenta"
    when 8
      s = s + "ochenta"
    when 9
      s = s + "noventa"
    end
    if ( n >= 30 )
      if (n%10).to_i != 0
        s = s + " y "
      end
      n = (n%10).to_i
    end
    case n          
    when 1
      if ( uno )
        s = s + "uno"
      else
        s = s + "un"
      end
    when 2
      s = s + "dos"
    when 3
      s = s + "tres"
    when 4
      s = s + "cuatro"
    when 5
      s = s + "cinco"
    when 6
      s = s + "seis"
    when 7
      s = s + "siete"
    when 8
      s = s + "ocho"
    when 9
      s = s + "nueve"
    when 10
      s = s + "diez"
    when 11
      s = s + "once"
    when 12
      s = s + "doce"
    when 13
      s = s + "trece"
    when 14
      s = s + "catorce"
    when 15
      s = s + "quince"
    when 16
      s = s + "dieciseis"
    when 17
      s = s + "diecisiete"
    when 18
      s = s + "dieciocho"
    when 19
      s = s + "diecinueve"
    when 20
      s = s + "veinte"
    when 21
      if uno
        s = s + "veintiuno"
      else
        s = s + "veintiun"
      end
    when 22
      s = s + "veintidos"
    when 23
      s = s + "veintitres"
    when 24
      s = s + "veinticuatro"
    when 25
      s = s + "veinticinco"
    when 26
      s = s + "veintiseis"
    when 27
      s = s + "veintisiete"
    when 28
      s = s + "veintiocho"
    when 29
      s = s + "veintinueve"
    end
    return s
  end

  def self.cedula_tos(cedula)
    if ( cedula == nil )
      return ""
    end
    return (cedula/10).to_s + "-" + (cedula%10).to_s
  end

  def fecha_tos(fecha)
    if ( fecha == nil )
      return ""
    end
    return I18n.l(fecha, format: '%-d de %B de %Y')
  end

  def self.numero_cuota_letras(cuota)
    s = ""
    case cuota
    when 1
      s = "primera"
    when 2
      s = "segunda"
    when 3
      s = "tercera"
    when 4
      s = "cuarta"
    when 5
      s = "quinta"
    when 6
      s = "sexta"
    when 7
      s = "septima"
    when 8
      s = "octava"
    when 9
      s = "novena"
    when 10
      s = "d\xE9cima"
    when 11
      s = "und\xE9cima"
    when 12
      s = "duod\xE9cima"
    when 13
      s = "decimotercera"
    when 14
      s = "decimocuarta"
    when 15
      s = "decimoquinta"
    when 16
      s = "decimosexta"
    when 17
      s = "decimoseptima"
    when 18
      s = "decimoctava"
    when 19
      s = "decimonovena"
    when 20
      s = "vig\xE9sima"
    when 21
      s = "vigesimoprimera"
    when 22
      s = "vigesimosegunda"
    when 23
      s = "vigesimotercera"
    when 24
      s = "vigesimocuarta"
    end
    return s.force_encoding('iso-8859-1')
  end


  def cuotas_a_letras(cuotas)
    if cuotas.count == 1
      if cuotas[0][0] == 1        
        return "<b>1</b> cuota de $U <b>#{cuotas[0][1]}</b>, venciendo el d\xEDa #{I18n.l(cuotas[0][2], format: '<b>%-d</b> de <b>%B</b> de <b>%Y</b>')}".force_encoding('iso-8859-1')
      else
        return "<b>#{cuotas[0][0]}</b> cuotas mensuales, iguales y consecutivas de $U <b>#{cuotas[0][1]}</b> cada una, venciendo la primera el d\xEDa #{I18n.l(cuotas[0][2], format: '<b>%-d</b> de <b>%B</b> de <b>%Y</b>')}".force_encoding('iso-8859-1')
      end
    else
      mensaje = "".force_encoding('iso-8859-1')
      cuota = 0
      cuotas.each do |c|
        if mensaje != "".force_encoding('iso-8859-1')
          mensaje = mensaje + ", ".force_encoding('iso-8859-1')
        end
        if c[0] == 1
          mensaje = mensaje + "la ".force_encoding('iso-8859-1') + Inscripcion2020.numero_cuota_letras(cuota+1) + " de $U <b>#{c[1]}</b> venciendo el d\xEDa #{I18n.l(c[2], format: '<b>%-d</b> de <b>%B</b> de <b>%Y</b>')}".force_encoding('iso-8859-1')
        else
          mensaje = mensaje + "de la ".force_encoding('iso-8859-1') + Inscripcion2020.numero_cuota_letras(cuota+1) + " a la ".force_encoding('iso-8859-1') + Inscripcion.numero_cuota_letras(cuota+c[0]) + " de $U <b>#{c[1]}</b> venciendo el d\xEDa #{I18n.l(c[2], format: '<b>%-d</b> de <b>%B</b> de <b>%Y</b>')} y cada mes subsiguiente".force_encoding('iso-8859-1')
        end
        cuota = cuota + c[0]
      end
      return "<b>#{cuota}</b> cuotas, a saber: ".force_encoding('iso-8859-1') + mensaje
    end
  end

  def convertStr(str)
    if str == nil
      return ""
    end
    return str.encode!(Encoding::ISO_8859_1)
  end

  def vale(file_path)

    alumno = Alumno.find(alumno_id) rescue nil
    padre = Usuario.find(padre_id) rescue nil
    madre = Usuario.find(madre_id) rescue nil
    titular1 = Usuario.find(titular1_id) rescue nil
    titular2 = Usuario.find(titular2_id) rescue nil

    cuotas = CalcularPrecio()

    total = 0
    cuotas.each do |cuota|
      total = total + cuota[0]*cuota[1]
    end
    total_letras = Inscripcion2020.numero_a_letras(total,true)

    cedula_alumno = Inscripcion2020.cedula_tos(alumno.cedula)
    nombre_alumno = ""
    if alumno != nil 
      nombre_alumno = convertStr(alumno.nombre + " " + alumno.apellido)
    end

    nombre_grado = ""
    proximo_grado = ProximoGrado.find(proximo_grado_id) rescue nil
    if proximo_grado != nil
      nombre_grado = convertStr(proximo_grado.nombre)
    end

    convenio_nombre = ""
    convenio = Convenio2020.find(convenio2020_id) rescue nil
    if convenio != nil
      convenio_nombre = convertStr("#{convenio.nombre} (#{convenio.descuento}%)")
    end

    afinidad_nombre = ""
    afinidad = Afinidad2020.find(afinidad2020_id) rescue nil
    if afinidad != nil
      afinidad_nombre = convertStr("#{afinidad.nombre} (#{afinidad.descuento}%)")
    end

    adicional_nombre = ""
    if adicional != nil
      adicional_nombre = convertStr("Adicional (#{adicional}%)")
    end
    
    congelado_nombre = ""
    if congelado != nil
      congelado_nombre = convertStr("Congelado (#{congelado}%)")
    end

    matricula_nombre = ""
    matricula = Matricula2020.find(matricula2020_id) rescue nil
    if matricula != nil
      matricula_nombre = convertStr(matricula.nombre)
    end

    hermanos_nombre = ""
    hermanos = Hermanos2020.find(hermanos2020_id) rescue nil
    if hermanos != nil
      hermanos_nombre = convertStr(hermanos.nombre)
    end

    idx=0
    nombreT = Array.new
    documentoT = Array.new
    domicilioT = Array.new
    emailT = Array.new
    celularT = Array.new

    if padre == nil
      padre = Usuario.new
    end
    if madre == nil
      madre = Usuario.new
    end

    if padre_titular != nil && padre_titular
      nombreT[idx] = convertStr("#{padre.nombre} #{padre.apellido}")
      documentoT[idx] = padre.cedula
      domicilioT[idx] = convertStr(padre.direccion)
      emailT[idx] = padre.email
      celularT[idx] = padre.celular
      idx = idx+1
    end

    if madre != nil && madre_titular != nil && madre_titular
      nombreT[idx] = convertStr("#{madre.nombre} #{madre.apellido}")
      documentoT[idx] = madre.cedula
      domicilioT[idx] = convertStr(madre.direccion)
      emailT[idx] = madre.email
      celularT[idx] = madre.celular
      idx = idx+1
    end

    if titular1 != nil
      nombreT[idx] = convertStr("#{titular1.nombre} #{titular1.apellido}")
      documentoT[idx] = titular1.cedula
      domicilioT[idx] = convertStr(titular1.direccion)
      emailT[idx] = titular1.email
      celularT[idx] = titular1.celular
      idx = idx+1
    end

    if titular2 != nil
      nombreT[idx] = convertStr("#{titular2.nombre} #{titular2.apellido}")
      documentoT[idx] = titular2.cedula
      domicilioT[idx] = convertStr(titular2.direccion)
      emailT[idx] = titular2.email
      celularT[idx] = titular2.celular
      idx = idx+1
    end

    if reinscripcion
      titulo = "<b>REINSCRIPCION</b>"
    else
      titulo = "<b>INSCRIPCION</b>"
    end

    texto_padre =
      "<b>PADRE</b><br>".force_encoding('iso-8859-1') +
      "Nombre: #{padre.nombre} #{padre.apellido}<br>".force_encoding('iso-8859-1') +
      "Documento de identidad: #{Inscripcion2020.cedula_tos(padre.cedula)}<br>".force_encoding('iso-8859-1') +
      "Lugar de nacimiento: #{padre.lugar_nacimiento}<br>".force_encoding('iso-8859-1') +
      "Fecha de nacimiento: #{fecha_tos(padre.fecha_nacimiento)}<br>".force_encoding('iso-8859-1') +
      "Mail: #{padre.email}<br>".force_encoding('iso-8859-1') + 
      "Domicilio: #{padre.direccion}<br>".force_encoding('iso-8859-1') + 
      "Tel\xE9fono/Celular: #{padre.celular}<br>".force_encoding('iso-8859-1') + 
      "Profesi\xF3n: #{padre.profesion}<br>".force_encoding('iso-8859-1') + 
      "Lugar de trabajo: #{padre.trabajo}<br>".force_encoding('iso-8859-1') + 
      "Tel\xE9fono de trabajo: #{padre.telefono_trabajo}<br>".force_encoding('iso-8859-1') 

    texto_madre =
      "<b>MADRE</b><br>".force_encoding('iso-8859-1') +
      "Nombre: #{madre.nombre} #{madre.apellido}<br>".force_encoding('iso-8859-1') +
      "Documento de identidad: #{Inscripcion2020.cedula_tos(madre.cedula)}<br>".force_encoding('iso-8859-1') +
      "Lugar de nacimiento: #{madre.lugar_nacimiento}<br>".force_encoding('iso-8859-1') +
      "Fecha de nacimiento: #{fecha_tos(madre.fecha_nacimiento)}<br>".force_encoding('iso-8859-1') +
      "Mail: #{madre.email}<br>".force_encoding('iso-8859-1') + 
      "Domicilio: #{madre.direccion}<br>".force_encoding('iso-8859-1') + 
      "Tel\xE9fono/Celular: #{madre.celular}<br>".force_encoding('iso-8859-1') + 
      "Profesi\xF3n: #{madre.profesion}<br>".force_encoding('iso-8859-1') + 
      "Lugar de trabajo: #{madre.trabajo}<br>".force_encoding('iso-8859-1') + 
      "Tel\xE9fono de trabajo: #{madre.telefono_trabajo}<br><br>".force_encoding('iso-8859-1')

    texto_nota = 
    "<b>NOTA: Para la inscripci\xF3n deber\xE1 presentar: fotocopia de la C.I. del/los Titular/es de la cuenta y si corresponde Libre de Deuda o recibo del \xFAltimo pago realizado en la Instituci\xF3n de donde proviene.<br><br>".force_encoding('iso-8859-1') +
           "LA AUTORIZACION DEFINITIVA SERA DADA UNA VEZ REALIZADO EL CLEARING DE INFORMES<br><br>".force_encoding('iso-8859-1') +
           "El que suscribe ______________________________ declara que los datos aportados son ciertos y actuales y los informa a los efectos de la contrataci\xF3n de los servicios educativos que el Colegio Nacional Jos\xE9 Pedro Varela provee. La actualizaci\xF3n de los datos prove\xEDdos es responsabilidad de la parte.</b>".force_encoding('iso-8859-1')



    informacion = 
      "El alumno ".force_encoding('iso-8859-1') +
      nombre_alumno.force_encoding('iso-8859-1') + 
      " cuya c\xE9dula es #{cedula_alumno} ha comenzado el proceso de reinscripci\xF3n para el a\xF1o lectivo #{anio} en ".force_encoding('iso-8859-1') + 
      nombre_grado.force_encoding('iso-8859-1') +
      " del Colegio Nacional Jos\xE9 Pedro Varela.".force_encoding('iso-8859-1')

    cabezal = 
      "$U <b>#{total}</b>".force_encoding('iso-8859-1') + 
      "<br><br>".force_encoding('iso-8859-1') +
      "Lugar y fecha de emisi\xF3n: <b>Montevideo, #{I18n.l(DateTime.now, format: '%-d de %B de %Y')}</b>".force_encoding('iso-8859-1')

    if cuotas.count==1 && cuotas[0][0] == 1
      texto = "<b>VALE</b>"
    else
      texto = "<b>VALE AMORTIZABLE</b>"
    end

    texto = texto + " por la cantidad de pesos uruguayos <b>#{total_letras}</b> que debo (debemos) y pagar\xE9 (pagaremos) en forma ".force_encoding('iso-8859-1') +
      "indivisible y solidaria a la Sociedad Uruguaya de Ense\xF1anza, Colegio Nacional Jos\xE9 Pedro Varela - o a su orden, en la misma moneda, en ".force_encoding('iso-8859-1') +
      "#{cuotas_a_letras(cuotas)}, en el domicilio del acreedor sito en la calle Colonia 1637 de la ciudad de Montevideo, o donde indique el acreedor.".force_encoding('iso-8859-1') +
      "<br><br>".force_encoding('iso-8859-1') + 
      "La falta de pago de dos o m\xE1s cuotas a su vencimiento producir\xE1 la mora de pleno derecho sin necesidad de interpelaci\xF3n de clase alguna, ".force_encoding('iso-8859-1') +
      "deveng\xE1ndose por esa sola circunstancias, intereses moratorios del 40% (cuarenta por ciento) tasa efectiva anual (aprobada por BCU) y har\xE1 ".force_encoding('iso-8859-1') +
      "exigible la totalidad del monto adeudado m\xE1s los intereses moratorios generados a partir del incumplimiento y hasta su efectiva y total ".force_encoding('iso-8859-1') + 
      "cancelaci\xF3n.".force_encoding('iso-8859-1') +
      "<br><br>".force_encoding('iso-8859-1') + 
      "En caso de incumplimiento total o parcial del presente t\xEDtulo, el acreedor a su elecci\xF3n, podr\xE1 demandar la ejecuci\xF3n de este t\xEDtulo ante ".force_encoding('iso-8859-1') +
      "los Jueces del lugar de residencia del deudor o ante los del lugar del cumplimiento de la obligaci\xF3n.".force_encoding('iso-8859-1') +
      "<br><br>".force_encoding('iso-8859-1') + 
      "Para todos los efectos judiciales y/o extrajudiciales a que pudiera dar lugar \xE9ste documento, el deudor constituye como domicilio especial el ".force_encoding('iso-8859-1') +
      "abajo denunciado.".force_encoding('iso-8859-1') +
      "<br><br><br>".force_encoding('iso-8859-1') + 
      "NOMBRE COMPLETO: #{nombreT[0]}<br><br>".force_encoding('iso-8859-1') +
      "DOCUMENTO DE IDENTIDAD: #{Inscripcion2020.cedula_tos(documentoT[0])}<br><br>".force_encoding('iso-8859-1') +
      "DOMICILIO: #{domicilioT[0]}<br><br>".force_encoding('iso-8859-1') +
      "MAIL: #{emailT[0]}<br><br>".force_encoding('iso-8859-1') +
      "TEL/CEL: #{celularT[0]}<br><br>".force_encoding('iso-8859-1') +
      "FIRMA:<br><br>".force_encoding('iso-8859-1') +
      "Aclaraci\xF3n:<br><br>".force_encoding('iso-8859-1') +
      "<br><br>".force_encoding('iso-8859-1') +
      "NOMBRE COMPLETO: #{nombreT[1]}<br><br>".force_encoding('iso-8859-1') +
      "DOCUMENTO DE IDENTIDAD: #{Inscripcion2020.cedula_tos(documentoT[1])}<br><br>".force_encoding('iso-8859-1') +
      "DOMICILIO: #{domicilioT[1]}<br><br>".force_encoding('iso-8859-1') +
      "MAIL: #{emailT[1]}<br><br>".force_encoding('iso-8859-1') +
      "TEL/CEL: #{celularT[1]}<br><br>".force_encoding('iso-8859-1') +
      "FIRMA:<br><br>".force_encoding('iso-8859-1') +
      "Aclaraci\xF3n:<br><br>".force_encoding('iso-8859-1')

    text_file = Tempfile.new("text.pdf")
    text_file_path = text_file.path

    reinsc = reinscripcion

    Prawn::Document.generate(text_file_path) do

      font "Helvetica", :size => 12

      dash 5, space: 0, phase:0
      stroke_color "0000FF"
      stroke_rectangle [0, 720], 540, 280
      stroke_color "FF0000"
      stroke_rectangle [2, 718], 536, 276

      image Rails.root.join("data", "logo.png"), at: [203,700], scale: 0.5

      bounding_box([20, 550], :width => 500, :height => 60) do
        text titulo, align: :center, inline_format: true
      end

      bounding_box([60, 530], :width => 420, :height => 60) do
        text informacion, align: :center, inline_format: true
      end

      bounding_box([0, 410], :width => 500, :height => 60) do
        text "Recibido por:", align: :left, inline_format: true
      end
      bounding_box([0, 390], :width => 500, :height => 60) do
        text "Fecha:", align: :left, inline_format: true
      end

      stroke_color "000000"
      dash 5, space: 5, phase:0
      stroke_horizontal_line -40, 580, at: 360

      dash 5, space: 0, phase:0
      stroke_color "0000FF"
      stroke_rectangle [0, 330], 540, 280
      stroke_color "FF0000"
      stroke_rectangle [2, 328], 536, 276

      image Rails.root.join("data", "logo.png"), at: [203,310], scale: 0.5

      bounding_box([20, 160], :width => 500, :height => 60) do
        text titulo, align: :center, inline_format: true
      end

      bounding_box([60, 140], :width => 420, :height => 60) do
        text informacion, align: :center, inline_format: true
      end

      bounding_box([0, 20], :width => 500, :height => 60) do
        text "Recibido por:", align: :left, inline_format: true
      end
      bounding_box([0, 0], :width => 500, :height => 60) do
        text "Fecha:", align: :left, inline_format: true
      end

      start_new_page

      font "Helvetica", :size => 10

      dash 5, space: 0, phase:0
      stroke_color "0000FF"
      stroke_rectangle [0, 720], 540, 720   
      stroke_color "FF0000"
      stroke_rectangle [2, 718], 536, 716

      bounding_box([20, 700], :width => 500, :height => 60) do
        text cabezal, align: :right, inline_format: true
      end
      bounding_box([20, 640], :width => 500, :height => 600) do
        text texto, align: :justify, inline_format: true
      end

    end

    pdf = CombinePDF.new
    pdf << CombinePDF.load(text_file_path)
    pdf.save file_path

    text_file.unlink

  end

end
