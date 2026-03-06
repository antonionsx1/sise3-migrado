<template>
  <div class="agenda-container">
    <!-- Encabezado -->
    <div class="agenda-header">
      <h2>📅 Agenda</h2>
      <div class="header-acciones">
        <button class="btn btn-primary">+ Agendar</button>
        <button class="btn btn-secondary">📊 Reporte</button>
        <button class="btn btn-secondary">🔔 Recordatorio</button>
      </div>
    </div>

    <!-- Controles del calendario -->
    <div class="agenda-controles">
      <!-- Modo de visualización -->
      <div class="control-grupo">
        <label>Vista:</label>
        <div class="btn-grupo">
          <button
            v-for="modo in modos" :key="modo.valor"
            :class="['btn-modo', { activo: store.modoVisualizacion === modo.valor }]"
            @click="store.modoVisualizacion = modo.valor"
          >{{ modo.label }}</button>
        </div>
      </div>

      <!-- Botón Hoy -->
      <button class="btn btn-hoy" @click="irAHoy">Hoy</button>

      <!-- Navegación -->
      <div class="control-grupo">
        <button class="btn-nav" @click="navegar(-1)">◀</button>
        <span class="fecha-actual">{{ fechaActualLabel }}</span>
        <button class="btn-nav" @click="navegar(1)">▶</button>
      </div>

      <!-- Mostrar/ocultar -->
      <div class="control-grupo">
        <label>
          <input type="checkbox" v-model="store.mostrarAudiencias" /> Audiencias
        </label>
        <label>
          <input type="checkbox" v-model="store.mostrarRecordatorios" /> Recordatorios
        </label>
      </div>
    </div>

    <!-- Filtro por estados -->
    <div class="filtro-estados">
      <button
        v-for="filtro in filtros" :key="filtro.valor"
        :class="['btn-filtro', { activo: store.filtroEstado === filtro.valor }]"
        @click="store.filtroEstado = filtro.valor"
      >{{ filtro.label }}</button>
    </div>

    <!-- Calendario simulado (vista Mes) -->
    <div class="calendario">
      <div class="calendario-header">
        <div v-for="dia in diasSemana" :key="dia" class="dia-header">{{ dia }}</div>
      </div>
      <div class="calendario-body">
        <div
          v-for="(dia, idx) in diasDelMes" :key="idx"
          :class="['dia-celda', { 'inhabil': dia.inhabil, 'hoy': dia.esHoy }]"
        >
          <span class="dia-numero">{{ dia.numero }}</span>
          <!-- Audiencias del día -->
          <template v-if="store.mostrarAudiencias">
            <div
              v-for="audiencia in audienciasPorDia(dia.fecha)"
              :key="audiencia.id"
              class="audiencia-chip"
              :style="{ background: store.colorEstado(audiencia.estado) }"
              @click="seleccionar(audiencia)"
            >
              {{ audiencia.tipoAudiencia }}
            </div>
          </template>
        </div>
      </div>
    </div>

    <!-- Detalle de audiencia -->
    <DetalleAudiencia
      v-if="store.audienciaSeleccionada"
      :audiencia="store.audienciaSeleccionada"
      @cerrar="store.audienciaSeleccionada = null"
    />
  </div>
</template>

<script>
import { agendaStore } from '../stores/agendaStore.js'
import DetalleAudiencia from '../components/DetalleAudiencia.vue'

export default {
  name: 'AgendaPage',
  components: { DetalleAudiencia },
  data() {
    return {
      store: agendaStore,
      fechaBase: new Date(),
      diasSemana: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
      modos: [
        { valor: 'Dia', label: 'Día' },
        { valor: 'Semana', label: 'Semana' },
        { valor: 'SemanaLaboral', label: 'Sem. Laboral' },
        { valor: 'Mes', label: 'Mes' }
      ],
      filtros: [
        { valor: 'VerTodo', label: 'Ver Todo' },
        { valor: 'Canceladas', label: 'Canceladas' },
        { valor: 'Diferidas', label: 'Diferidas' },
        { valor: 'Celebradas', label: 'Celebradas' }
      ]
    }
  },
  computed: {
    fechaActualLabel() {
      return this.fechaBase.toLocaleDateString('es-MX', { month: 'long', year: 'numeric' })
    },
    diasDelMes() {
      const año = this.fechaBase.getFullYear()
      const mes = this.fechaBase.getMonth()
      const hoy = new Date()
      const diasEnMes = new Date(año, mes + 1, 0).getDate()
      const dias = []
      for (let d = 1; d <= diasEnMes; d++) {
        const fecha = new Date(año, mes, d)
        const diaSemana = fecha.getDay()
        dias.push({
          numero: d,
          fecha,
          inhabil: diaSemana === 0 || diaSemana === 6,
          esHoy: fecha.toDateString() === hoy.toDateString()
        })
      }
      return dias
    }
  },
  methods: {
    irAHoy() {
      this.fechaBase = new Date()
    },
    navegar(dir) {
      const f = new Date(this.fechaBase)
      f.setMonth(f.getMonth() + dir)
      this.fechaBase = f
    },
    audienciasPorDia(fecha) {
      if (!fecha) return []
      return this.store.audienciasFiltradas.filter(a =>
        new Date(a.fechaHora).toDateString() === fecha.toDateString()
      )
    },
    seleccionar(audiencia) {
      this.store.audienciaSeleccionada = audiencia
    }
  }
}
</script>

<style scoped>
.agenda-container { font-family: sans-serif; padding: 20px; max-width: 1100px; margin: 0 auto; }
.agenda-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.agenda-header h2 { margin: 0; font-size: 1.5rem; color: #2d3748; }
.header-acciones { display: flex; gap: 8px; }
.btn { padding: 7px 14px; border: none; border-radius: 6px; cursor: pointer; font-size: 0.9rem; }
.btn-primary { background: #3182ce; color: white; }
.btn-secondary { background: #e2e8f0; color: #2d3748; }
.btn-hoy { background: #edf2f7; border: 1px solid #cbd5e0; border-radius: 6px; padding: 6px 14px; cursor: pointer; }
.agenda-controles { display: flex; align-items: center; gap: 16px; flex-wrap: wrap; margin-bottom: 12px; }
.control-grupo { display: flex; align-items: center; gap: 6px; }
.btn-grupo { display: flex; }
.btn-modo { padding: 5px 12px; border: 1px solid #cbd5e0; background: white; cursor: pointer; }
.btn-modo:first-child { border-radius: 6px 0 0 6px; }
.btn-modo:last-child { border-radius: 0 6px 6px 0; }
.btn-modo.activo { background: #3182ce; color: white; border-color: #3182ce; }
.btn-nav { background: none; border: 1px solid #cbd5e0; border-radius: 4px; padding: 4px 10px; cursor: pointer; }
.fecha-actual { font-weight: 600; min-width: 160px; text-align: center; text-transform: capitalize; }
.filtro-estados { display: flex; gap: 8px; margin-bottom: 16px; }
.btn-filtro { padding: 6px 14px; border: 1px solid #cbd5e0; border-radius: 20px; background: white; cursor: pointer; font-size: 0.88rem; }
.btn-filtro.activo { background: #2d3748; color: white; border-color: #2d3748; }
.calendario { border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden; }
.calendario-header { display: grid; grid-template-columns: repeat(7, 1fr); background: #f7fafc; }
.dia-header { padding: 10px; text-align: center; font-weight: 600; font-size: 0.85rem; color: #4a5568; }
.calendario-body { display: grid; grid-template-columns: repeat(7, 1fr); }
.dia-celda { min-height: 90px; padding: 6px; border: 1px solid #e2e8f0; }
.dia-celda.inhabil { background: #f7fafc; opacity: 0.6; }
.dia-celda.hoy { background: #ebf8ff; }
.dia-numero { font-size: 0.85rem; font-weight: 600; color: #4a5568; display: block; margin-bottom: 4px; }
.audiencia-chip { color: white; border-radius: 4px; padding: 2px 6px; font-size: 0.75rem; margin-bottom: 3px; cursor: pointer; truncate: true; }
.audiencia-chip:hover { opacity: 0.85; }
</style>
