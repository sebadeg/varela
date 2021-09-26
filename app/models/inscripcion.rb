class Inscripcion < ApplicationRecord
  belongs_to :proximo_grado

  def self.FindInscripcion(a)
    inscripcion = Inscripcion.where("alumno_id=#{a} AND reinscripcion AND anio IN (SELECT anio_inscripciones FROM configs WHERE NOT anio_inscripciones IS NULL)").order(anio: :desc).first rescue nil

    alumno = Alumno.find(inscripcion.alumno_id) rescue nil
    if alumno != nil
      inscripcion.nombre = alumno.nombre
      inscripcion.apellido = alumno.apellido
      inscripcion.lugar_nacimiento = alumno.lugar_nacimiento
      inscripcion.fecha_nacimiento = alumno.fecha_nacimiento
      inscripcion.domicilio = alumno.domicilio
      inscripcion.celular = alumno.celular
      inscripcion.mutualista = alumno.mutualista
      inscripcion.emergencia = alumno.emergencia
    end
   
    return inscripcion

  end

  def Formulario() 
    return ""
  end

  def FindInscripcionOpcion(inscripcionOpcion) 
    inscripcionOpcion = InscripcionOpcion.where("id = #{inscripcionOpcion}").first rescue nil
    if inscripcionOpcion == nil
      return ""
    else
      return inscripcionOpcion.nombre
    end
  end

  def PuedeInscribir()
    return (inhabilitado != nil) && !inhabilitado && (fecha_pase == nil)
  end

  def EstaInscripto()
    return (inscripto != nil) && inscripto
  end

  def HayVale()
    return (hay_vale != nil) && hay_vale
  end

  def EstaRegistrado()
    return (registrado != nil) && registrado
  end

  def CalcularPrecio()

    cuotas = Array.new

    proximo_grado = ProximoGrado.find(proximo_grado_id) rescue nil
    if proximo_grado == nil
      return cuotas
    end

    importe_total = proximo_grado.precio

    descuentos = Array.new

    # formulario = Formulario.find(formulario_id) rescue nil
    # FormularioInscripcionOpcion.where("formulario_id=#{formulario_id} AND inscripcion_opcion_id IN (SELECT id FROM inscripcion_opciones WHERE " +
    #   "inscripcion_opcion_tipo_id IN (SELECT id FROM inscripcion_opcion_tipos WHERE nombre='Convenio' AND NOT id IS NULL))"
    #   ).each do |formulario_inscripcion_opcion|
    #   descuentos.push(formulario_inscripcion_opcion.inscripcion_opcion_id)
    # end
    descuentos.push(convenio_id)

    # FormularioInscripcionOpcion.where("formulario_id=#{formulario_id} AND inscripcion_opcion_id IN (SELECT id FROM inscripcion_opciones WHERE " +
    #   "inscripcion_opcion_tipo_id IN (SELECT id FROM inscripcion_opcion_tipos WHERE nombre='Adicional' AND NOT id IS NULL))"
    #   ).each do |formulario_inscripcion_opcion|
    #   descuentos.push(formulario_inscripcion_opcion.inscripcion_opcion_id)
    # end
    descuentos.push(adicional_id)

    # FormularioInscripcionOpcion.where("formulario_id=#{formulario_id} AND inscripcion_opcion_id IN (SELECT id FROM inscripcion_opciones WHERE " +
    #   "inscripcion_opcion_tipo_id IN (SELECT id FROM inscripcion_opcion_tipos WHERE nombre='Hermanos' AND NOT id IS NULL))"
    #   ).each do |formulario_inscripcion_opcion|
    #   descuentos.push(formulario_inscripcion_opcion.inscripcion_opcion_id)
    # end
    descuentos.push(hermanos_id)

    p "------------------------------"
    p "------------------------------"
    p "------------------------------"
    p importe_total
    p descuentos


    descuentos.each do |inscripcion_opcion_id|
      inscripcion_opcion = InscripcionOpcion.find(inscripcion_opcion_id) rescue nil
      if inscripcion_opcion != nil 
        if inscripcion_opcion.valor == nil
          importe_total = 0
          InscripcionOpcionCuota.where("inscripcion_opcion_id=#{inscripcion_opcion.id}").order(:fecha).each do |cuota|
            importe_total = importe_total + cuota.cantidad*cuota.importe
          end
        else
          importe_total = importe_total * ( 100.0 - inscripcion_opcion.valor ) / 100.0
        end
      end
    end

    p importe_total
    p "------------------------------"
    p "------------------------------"
    p "------------------------------"

    #numero_cuotas = 0
    #fecha_cuota = nil
    # if formulario_id != nil
    #   InscripcionOpcion.where( "id IN (SELECT inscripcion_opcion_id FROM formulario_inscripcion_opciones " +
    #     "WHERE formulario_id=#{formulario_id} AND NOT inscripcion_opcion_id IS NULL) AND " +
    #     "inscripcion_opcion_tipo_id IN (SELECT id FROM inscripcion_opcion_tipos WHERE nombre='Cuotas' AND NOT id IS NULL)"
    #     ).each do |inscripcion_opcion_cuotas|
    #     if ( inscripcion_opcion_cuotas.valor == nil )
    #       numero_cuotas = inscripcion_opcion_cuotas.valor_ent
    #       if fecha_cuota == nil
    #         fecha_cuota = inscripcion_opcion_cuotas.fecha
    #       end
    #     else            
    #       cuotas.push([inscripcion_opcion_cuotas.valor_ent,inscripcion_opcion_cuotas.valor,inscripcion_opcion_cuotas.fecha])
    #     end
    #   end        
    # else
      inscripcion_opcion_cuotas = InscripcionOpcion.find(cuotas_id) rescue nil 
      if inscripcion_opcion_cuotas != nil
        InscripcionOpcionCuota.where("inscripcion_opcion_id=#{inscripcion_opcion_cuotas.id}").order(:fecha).each do |cuota|
          cuotas.push([cuota.cantidad,(importe_total*cuota.importe+0.5).to_i,cuota.fecha + 9.days])
        end
        # if ( inscripcion_opcion_cuotas.valor == nil )
        #   numero_cuotas = inscripcion_opcion_cuotas.valor_ent
        #   fecha_cuota = inscripcion_opcion_cuotas.fecha
        # else            
        #   cuotas.push([inscripcion_opcion_cuotas.valor_ent,inscripcion_opcion_cuotas.valor,inscripcion_opcion_cuotas.fecha])
        # end
      end
    #end     

    # if cuotas.count == 0 && numero_cuotas != 0 
    #   cuotas.push([numero_cuotas,(importe_total/numero_cuotas+0.5).to_i,fecha_cuota])
    # end

    return cuotas
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
          mensaje = mensaje + "la ".force_encoding('iso-8859-1') + Inscripcion.numero_cuota_letras(cuota+1) + " de $U <b>#{c[1]}</b> venciendo el d\xEDa #{I18n.l(c[2], format: '<b>%-d</b> de <b>%B</b> de <b>%Y</b>')}".force_encoding('iso-8859-1')
        else
          mensaje = mensaje + "de la ".force_encoding('iso-8859-1') + Inscripcion.numero_cuota_letras(cuota+1) + " a la ".force_encoding('iso-8859-1') + Inscripcion.numero_cuota_letras(cuota+c[0]) + " de $U <b>#{c[1]}</b> venciendo el d\xEDa #{I18n.l(c[2], format: '<b>%-d</b> de <b>%B</b> de <b>%Y</b>')} y cada mes subsiguiente".force_encoding('iso-8859-1')
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

    cuotas = CalcularPrecio()

    total = 0
    cuotas.each do |cuota|
      total = total + cuota[0]*cuota[1]
    end


    total_letras = Inscripcion.numero_a_letras(total,true)

    cedula_alumno = Inscripcion.cedula_tos(cedula)

    nombre_alumno = ""
    alumno = Alumno.find_by(cedula: cedula) rescue nil
    if alumno != nil 
      nombre_alumno = convertStr(alumno.nombre) + " " + convertStr(alumno.apellido)
    end

    nombre_grado = ""
    proximo_grado = ProximoGrado.find(proximo_grado_id) rescue nil
    if proximo_grado != nil
      nombre_grado = convertStr(proximo_grado.nombre)
    end

    convenio_nombre = ""
    matricula_nombre = ""
    hermanos_nombre = ""
    if formulario_id != nil
      formulario = Formulario.find(formulario_id) rescue nil
      if formulario != nil 
        convenio_nombre = formulario.nombre
      end
    else
      inscripcion_opcion = InscripcionOpcion.find(convenio_id) rescue nil
      if inscripcion_opcion != nil 
        convenio_nombre = convertStr(inscripcion_opcion.nombre)
      end
      inscripcion_opcion = InscripcionOpcion.find(adicional_id) rescue nil
      if inscripcion_opcion != nil 
        convenio_nombre = convertStr(convenio_nombre) + " + " + convertStr(inscripcion_opcion.nombre)
      end

      inscripcion_opcion = InscripcionOpcion.find(matricula_id) rescue nil
      if inscripcion_opcion != nil 
        matricula_nombre = convertStr(inscripcion_opcion.nombre)
      end

      inscripcion_opcion = InscripcionOpcion.find(hermanos_id) rescue nil
      if inscripcion_opcion != nil 
        hermanos_nombre = convertStr(inscripcion_opcion.nombre)
      end
    end

    inscripcion = Inscripcion.FindInscripcion(alumno_id)

    idx=0
    nombreT = Array.new
    documentoT = Array.new
    domicilioT = Array.new
    emailT = Array.new
    celularT = Array.new

    if (inscripcion.titular_padre)
      nombreT[idx] = "#{convertStr(inscripcion.nombre_padre)} #{convertStr(inscripcion.apellido_padre)}"
      documentoT[idx] = inscripcion.cedula_padre
      domicilioT[idx] = convertStr(inscripcion.domicilio_padre)
      emailT[idx] = inscripcion.email_padre
      celularT[idx] = inscripcion.celular_padre
      idx = idx+1
    end

    if (inscripcion.titular_madre)
      nombreT[idx] = "#{convertStr(inscripcion.nombre_madre)} #{convertStr(inscripcion.apellido_madre)}"
      documentoT[idx] = inscripcion.cedula_madre
      domicilioT[idx] = convertStr(inscripcion.domicilio_madre)
      emailT[idx] = inscripcion.email_madre
      celularT[idx] = inscripcion.celular_madre
      idx = idx+1
    end

    if inscripcion.documento1 != nil
      nombreT[idx] = "#{convertStr(inscripcion.nombre1)} #{convertStr(inscripcion.apellido1)}"
      documentoT[idx] = inscripcion.documento1
      domicilioT[idx] = convertStr(inscripcion.domicilio1)
      emailT[idx] = inscripcion.email1
      celularT[idx] = inscripcion.celular1
      idx = idx+1
    end

    if inscripcion.documento2 != nil
      nombreT[idx] = "#{convertStr(inscripcion.nombre2)} #{convertStr(inscripcion.apellido2)}"
      documentoT[idx] = inscripcion.documento2
      domicilioT[idx] = convertStr(inscripcion.domicilio2)
      emailT[idx] = inscripcion.email2
      celularT[idx] = inscripcion.celular2
      idx = idx+1
    end


    if reinscripcion
      titulo = "<b>REINSCRIPCION</b>"
    else
      titulo = "<b>INSCRIPCION</b>"
    end

    texto_inscripcion =
      "#{titulo}<br>".force_encoding('iso-8859-1') +      
      "Fecha: #{fecha_tos(inscripcion.created_at)}<br>".force_encoding('iso-8859-1') +
      "Recibida por: #{inscripcion.recibida}<br>".force_encoding('iso-8859-1') +
      "<br>".force_encoding('iso-8859-1') +
      "<b>NIVEL</b><br>".force_encoding('iso-8859-1') +
      "Grado: #{nombre_grado}<br>".force_encoding('iso-8859-1') +
      "Descuento: #{convenio_nombre}<br>".force_encoding('iso-8859-1') +
      "Matr\xEDcula: #{matricula_nombre}<br>".force_encoding('iso-8859-1') +
      "Hermanos: #{hermanos_nombre}<br>".force_encoding('iso-8859-1') +
      "<br>".force_encoding('iso-8859-1') +
      "<b>ALUMNO</b><br>".force_encoding('iso-8859-1') +
      "Nombre: #{inscripcion.nombre} #{inscripcion.apellido}<br>".force_encoding('iso-8859-1') +
      "Documento de identidad: #{Inscripcion.cedula_tos(inscripcion.cedula)}<br>".force_encoding('iso-8859-1') +
      "Lugar de nacimiento: #{inscripcion.lugar_nacimiento}<br>".force_encoding('iso-8859-1') +
      "Fecha de nacimiento: #{fecha_tos(inscripcion.fecha_nacimiento)}<br>".force_encoding('iso-8859-1') +
      "Domicilio: #{inscripcion.domicilio}<br>".force_encoding('iso-8859-1') + 
      "Tel\xE9fono/Celular: #{inscripcion.celular}<br>".force_encoding('iso-8859-1') + 
      "Mutualista: #{inscripcion.mutualista}<br>".force_encoding('iso-8859-1') + 
      "Emergencia: #{inscripcion.emergencia}<br>".force_encoding('iso-8859-1') + 
      "Procede de: #{inscripcion.procede}<br>".force_encoding('iso-8859-1')

    texto_padre =
      "<b>PADRE</b><br>".force_encoding('iso-8859-1') +
      "Nombre: #{inscripcion.nombre_padre} #{inscripcion.apellido_padre}<br>".force_encoding('iso-8859-1') +
      "Documento de identidad: #{Inscripcion.cedula_tos(inscripcion.cedula_padre)}<br>".force_encoding('iso-8859-1') +
      "Lugar de nacimiento: #{inscripcion.lugar_nacimiento_padre}<br>".force_encoding('iso-8859-1') +
      "Fecha de nacimiento: #{fecha_tos(inscripcion.fecha_nacimiento_padre)}<br>".force_encoding('iso-8859-1') +
      "Mail: #{inscripcion.email_padre}<br>".force_encoding('iso-8859-1') + 
      "Domicilio: #{inscripcion.domicilio_padre}<br>".force_encoding('iso-8859-1') + 
      "Tel\xE9fono/Celular: #{inscripcion.celular_padre}<br>".force_encoding('iso-8859-1') + 
      "Profesi\xF3n: #{inscripcion.profesion_padre}<br>".force_encoding('iso-8859-1') + 
      "Lugar de trabajo: #{inscripcion.trabajo_padre}<br>".force_encoding('iso-8859-1') + 
      "Tel\xE9fono de trabajo: #{inscripcion.telefono_trabajo_padre}<br>".force_encoding('iso-8859-1') 

    texto_madre =
      "<b>MADRE</b><br>".force_encoding('iso-8859-1') +
      "Nombre: #{inscripcion.nombre_madre} #{inscripcion.apellido_madre}<br>".force_encoding('iso-8859-1') +
      "Documento de identidad: #{Inscripcion.cedula_tos(inscripcion.cedula_madre)}<br>".force_encoding('iso-8859-1') +
      "Lugar de nacimiento: #{inscripcion.lugar_nacimiento_madre}<br>".force_encoding('iso-8859-1') +
      "Fecha de nacimiento: #{fecha_tos(inscripcion.fecha_nacimiento_madre)}<br>".force_encoding('iso-8859-1') +
      "Mail: #{inscripcion.email_madre}<br>".force_encoding('iso-8859-1') + 
      "Domicilio: #{inscripcion.domicilio_madre}<br>".force_encoding('iso-8859-1') + 
      "Tel\xE9fono/Celular: #{inscripcion.celular_madre}<br>".force_encoding('iso-8859-1') + 
      "Profesi\xF3n: #{inscripcion.profesion_madre}<br>".force_encoding('iso-8859-1') + 
      "Lugar de trabajo: #{inscripcion.trabajo_madre}<br>".force_encoding('iso-8859-1') + 
      "Tel\xE9fono de trabajo: #{inscripcion.telefono_trabajo_madre}<br><br>".force_encoding('iso-8859-1')

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
      "DOCUMENTO DE IDENTIDAD: #{Inscripcion.cedula_tos(documentoT[0])}<br><br>".force_encoding('iso-8859-1') +
      "DOMICILIO: #{domicilioT[0]}<br><br>".force_encoding('iso-8859-1') +
      "MAIL: #{emailT[0]}<br><br>".force_encoding('iso-8859-1') +
      "TEL/CEL: #{celularT[0]}<br><br>".force_encoding('iso-8859-1') +
      "FIRMA:<br><br>".force_encoding('iso-8859-1') +
      "Aclaraci\xF3n:<br><br>".force_encoding('iso-8859-1') +
      "<br><br>".force_encoding('iso-8859-1') +
      "NOMBRE COMPLETO: #{nombreT[1]}<br><br>".force_encoding('iso-8859-1') +
      "DOCUMENTO DE IDENTIDAD: #{Inscripcion.cedula_tos(documentoT[1])}<br><br>".force_encoding('iso-8859-1') +
      "DOMICILIO: #{domicilioT[1]}<br><br>".force_encoding('iso-8859-1') +
      "MAIL: #{emailT[1]}<br><br>".force_encoding('iso-8859-1') +
      "TEL/CEL: #{celularT[1]}<br><br>".force_encoding('iso-8859-1') +
      "FIRMA:<br><br>".force_encoding('iso-8859-1') +
      "Aclaraci\xF3n:<br><br>".force_encoding('iso-8859-1')

    text_file = Tempfile.new("text.pdf")
    text_file_path = text_file.path

    reinsc = reinscripcion

    Prawn::Document.generate(text_file_path) do

      if reinsc
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




        # bounding_box([0, 700], :width => 500, :height => 60) do
        #   text "Recibido por:", align: :left, inline_format: true
        # end
        # bounding_box([0, 680], :width => 500, :height => 60) do
        #   text "Fecha:", align: :left, inline_format: true
        # end

        start_new_page
      end

      if !reinsc
        font "Helvetica", :size => 10
        
        dash 5, space: 0, phase:0
        stroke_color "0000FF"
        stroke_rectangle [0, 720], 540, 720   
        stroke_color "FF0000"
        stroke_rectangle [2, 718], 536, 716

        image Rails.root.join("data", "logo.png"), at: [203,700], scale: 0.5

        bounding_box([20, 570], :width => 500, :height => 300) do
          text texto_inscripcion, align: :left, inline_format: true
        end

        bounding_box([20, 280], :width => 250, :height => 150) do
          text texto_padre, align: :left, inline_format: true
        end

        bounding_box([270, 280], :width => 250, :height => 150) do
          text texto_madre, align: :left, inline_format: true
        end

        bounding_box([20, 120], :width => 500, :height => 120) do
          text texto_nota, align: :justify, inline_format: true
        end

        start_new_page
      end

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
