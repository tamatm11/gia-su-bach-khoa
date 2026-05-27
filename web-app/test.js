const { supabase } = require('./lib/supabase');

async function main() {
  const { data, error } = await supabase
    .from('ung_tuyen')
    .select('*, yeu_cau_lop(*, hoc_vien(ho_ten))')
    .order('ngay_ung_tuyen', { ascending: false })
    .limit(1);

  console.log(JSON.stringify({ data, error }, null, 2));
}

main();
