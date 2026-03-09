import { reactive } from 'vue'

// Datos simulados de audiencias
const audiencias = [
  {
    id: 1,
    numeroExpediente: '001/2026',
    tipoAsunto: 'Penal',
    tipoProcedimiento: 'Oral',
    fechaHora: new Date().toISOString(),
    tipoAudiencia: 'Inicial',
    secretario: 'Juan Pérez',
    partesInteresadas: 'Parte A, Parte B',
    personaQueAgenda: 'Laura Cortes',
    estado: 'Celebrada'
  },
  {
    id: 2,
    numeroExpediente: '002/2026',
    tipoAsunto: 'Civil',
    tipoProcedimiento: 'Oral',
    fechaHora: new Date().toISOString(),
    tipoAudiencia: 'Desahogo',
    secretario: 'María López',
    partesInteresadas: 'Parte C, Parte D',
    personaQueAgenda: 'Laura Cortes',
    estado: 'Cancelada'
  },
  {
    id: 3,
    numeroExpediente: '003/2026',
    tipoAsunto: 'Familiar',
    tipoProcedimiento: 'Oral',
    fechaHora: new Date().toISOString(),
    tipoAudiencia: 'Sentencia',
    secretario: 'Carlos Ruiz',
    partesInteresadas: 'Parte E, Parte F',
    personaQueAgenda: 'Laura Cortes',
    estado: 'Diferida'
  }
]

export const agendaStore = reactive({
  // Estado del filtro actual
  filtroEstado: 'VerTodo', // VerTodo, Canceladas, Diferidas, Celebradas

  // Modo de visualización
  modoVisualizacion: 'Mes', // Dia, Semana, SemanaLaboral, Mes

  // Mostrar audiencias y/o recordatorios
  mostrarAudiencias: true,
  mostrarRecordatorios: false,

  // Audiencia seleccionada para ver detalle
  audienciaSeleccionada: null,

  // Todas las audiencias
  audiencias,

  // Audiencias filtradas según estado seleccionado
  get audienciasFiltradas() {
    if (this.filtroEstado === 'VerTodo') return this.audiencias
    const mapa = {
      Canceladas: 'Cancelada',
      Diferidas: 'Diferida',
      Celebradas: 'Celebrada'
    }
    return this.audiencias.filter(a => a.estado === mapa[this.filtroEstado])
  },

  // Color por estado
  colorEstado(estado) {
    const colores = {
      Cancelada: '#e53e3e',
      Diferida: '#d69e2e',
      Celebrada: '#38a169'
    }
    return colores[estado] || '#3182ce'
  }
})
